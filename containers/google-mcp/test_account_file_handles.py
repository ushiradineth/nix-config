from contextlib import asynccontextmanager
from datetime import datetime, timedelta
from pathlib import Path
import inspect
from unittest.mock import AsyncMock, Mock

import pytest

import core.attachment_storage as attachment_storage
from gdrive import drive_helpers
from core.file_handles import resolve_file_handle
from gdrive import drive_tools
from core import server as core_server
from starlette.requests import Request
from gmail import gmail_tools


@pytest.fixture
def stored_handle(tmp_path, monkeypatch):
    monkeypatch.setattr(attachment_storage, "STORAGE_DIR", tmp_path / "attachments")
    monkeypatch.setenv("WORKSPACE_EXTERNAL_URL", "https://mcp.example")
    storage = attachment_storage.AttachmentStorage()
    monkeypatch.setattr(attachment_storage, "_attachment_storage", storage)
    saved = storage.save_attachment_bytes(
        b"original",
        filename="report.pdf",
        mime_type="application/pdf",
        owner_email="alice@example.com",
    )
    return storage, saved, f"https://mcp.example/attachments/{saved.file_id}"


@pytest.mark.parametrize("caller", [None, "bob@example.com", ""])
def test_handle_rejects_other_or_missing_identity(stored_handle, caller):
    _, _, url = stored_handle
    with pytest.raises(ValueError, match="not authorized"):
        resolve_file_handle(url, caller)


def test_expired_handle_is_rejected_and_cleaned(stored_handle):
    storage, saved, url = stored_handle
    storage._metadata[saved.file_id]["expires_at"] = datetime.now() - timedelta(
        seconds=1
    )
    with pytest.raises(ValueError, match="expired or unavailable"):
        resolve_file_handle(url, "alice@example.com")
    assert not Path(saved.path).exists()


def test_restart_invalidates_old_handles(stored_handle, monkeypatch):
    _, _, url = stored_handle
    monkeypatch.setattr(
        attachment_storage,
        "_attachment_storage",
        attachment_storage.AttachmentStorage(),
    )
    with pytest.raises(ValueError, match="expired or unavailable"):
        resolve_file_handle(url, "alice@example.com")


def test_tampered_bytes_fail_integrity_check(stored_handle):
    _, saved, url = stored_handle
    Path(saved.path).write_bytes(b"modified")
    with pytest.raises(ValueError, match="integrity check failed"):
        resolve_file_handle(url, "alice@example.com")


def test_symlink_is_never_followed(stored_handle, tmp_path):
    _, saved, url = stored_handle
    target = tmp_path / "outside"
    target.write_bytes(b"original")
    Path(saved.path).unlink()
    Path(saved.path).symlink_to(target)
    with pytest.raises(ValueError, match="invalid storage path"):
        resolve_file_handle(url, "alice@example.com")


@pytest.mark.parametrize("suffix", ["?x=1", "#fragment", "/../secret", "/extra"])
def test_malformed_handles_fail_closed(stored_handle, suffix):
    _, _, url = stored_handle
    with pytest.raises(ValueError, match="Invalid MCP file handle"):
        resolve_file_handle(url + suffix, "alice@example.com")


def test_foreign_origin_cannot_resolve_local_bytes(stored_handle):
    _, _, url = stored_handle
    assert (
        resolve_file_handle(
            url.replace("mcp.example", "evil.example"), "alice@example.com"
        )
        is None
    )


@pytest.mark.asyncio
async def test_drive_create_consumes_handle_with_local_files_disabled(
    stored_handle, monkeypatch
):
    _, _, url = stored_handle
    monkeypatch.setenv("WORKSPACE_MCP_DISABLE_LOCAL_FILES", "true")
    monkeypatch.setattr(
        drive_tools, "resolve_folder_id", AsyncMock(return_value="folder")
    )
    service = Mock()
    captured = {}

    def upload(**_kwargs):
        media = service.files.return_value.create.call_args.kwargs["media_body"]
        captured["bytes"] = media.getbytes(0, 8)
        return {"id": "created", "name": "report.pdf"}

    service.files.return_value.create.return_value.execute.side_effect = upload
    fn = inspect.unwrap(drive_tools.create_drive_file)
    result = await fn(
        service=service,
        user_google_email="alice@example.com",
        file_name="report.pdf",
        folder_id="folder",
        mime_type="application/pdf",
        fileUrl=url,
    )
    assert captured["bytes"] == b"original"
    assert "Successfully created file" in result


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "caller, expected",
    [("alice@example.com", 200), ("bob@example.com", 403), (None, 403)],
)
async def test_http_download_requires_owner_token(
    stored_handle, monkeypatch, caller, expected
):
    _, saved, _ = stored_handle
    provider = Mock()
    provider.verify_token = AsyncMock(return_value=Mock(email=caller, claims={}))
    monkeypatch.setattr(core_server, "get_auth_provider", lambda: provider)
    monkeypatch.setattr(
        "auth.oauth_callback_server.ensure_stdio_oauth_callback_available",
        lambda: (True, None),
    )
    headers = [(b"authorization", b"Bearer test-token")] if caller else []
    request = Request(
        {
            "type": "http",
            "method": "GET",
            "scheme": "http",
            "server": ("internal", 8000),
            "path": f"/attachments/{saved.file_id}",
            "headers": headers,
            "query_string": b"",
            "path_params": {"file_id": saved.file_id},
        }
    )
    response = await core_server.serve_attachment(request)
    assert response.status_code == expected


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "tool, mime, filename",
    [
        (drive_tools.import_to_google_doc, "text/plain", "report.txt"),
        (drive_tools.import_to_google_sheets, "text/csv", "report.csv"),
        (
            drive_tools.import_to_google_slides,
            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "report.pptx",
        ),
    ],
)
async def test_native_import_consumes_same_shared_handle(
    stored_handle, monkeypatch, tool, mime, filename
):
    storage, _, _ = stored_handle
    saved = storage.save_attachment_bytes(
        b"source-bytes",
        filename=filename,
        mime_type=mime,
        owner_email="alice@example.com",
    )
    monkeypatch.setattr(
        drive_helpers, "resolve_folder_id", AsyncMock(return_value="folder")
    )
    service = Mock()
    captured = {}

    def upload(**_kwargs):
        media = service.files.return_value.create.call_args.kwargs["media_body"]
        captured["bytes"] = media.getbytes(0, 12)
        captured["mime"] = media.mimetype()
        return {"id": "converted", "name": "report"}

    service.files.return_value.create.return_value.execute.side_effect = upload
    await inspect.unwrap(tool)(
        service=service,
        user_google_email="alice@example.com",
        file_name=filename,
        file_url=f"https://mcp.example/attachments/{saved.file_id}",
    )
    assert captured == {"bytes": b"source-bytes", "mime": mime}


@pytest.mark.asyncio
async def test_gmail_consumes_same_shared_handle_and_denies_other_account(
    stored_handle,
):
    _, _, url = stored_handle
    result = await gmail_tools._resolve_url_attachments(
        [{"url": url}], "alice@example.com"
    )
    assert result[0]["_resolved_bytes"] == b"original"
    denied = await gmail_tools._resolve_url_attachments(
        [{"url": url}], "bob@example.com"
    )
    assert "not authorized" in denied[0]["error"]
    assert "_resolved_bytes" not in denied[0]


@pytest.mark.asyncio
async def test_handle_upload_reuses_stored_stream_and_enforces_limit(
    stored_handle, monkeypatch
):
    _, saved, url = stored_handle
    stream, mime = await drive_helpers._download_url_to_bytes(
        url, user_google_email="alice@example.com"
    )
    try:
        assert Path(stream.name) == Path(saved.path)
        assert stream.read() == b"original"
        assert mime == "application/pdf"
    finally:
        stream.close()
    monkeypatch.setenv("WORKSPACE_MCP_MAX_FILE_BYTES", "4")
    with pytest.raises(ValueError, match="limit"):
        await drive_helpers._download_url_to_bytes(
            url, user_google_email="alice@example.com"
        )


@pytest.mark.asyncio
async def test_same_account_large_handle_streams_without_network(tmp_path, monkeypatch):
    monkeypatch.setattr(attachment_storage, "STORAGE_DIR", tmp_path / "attachments")
    monkeypatch.setenv("WORKSPACE_EXTERNAL_URL", "https://mcp.example")
    storage = attachment_storage.AttachmentStorage()
    monkeypatch.setattr(attachment_storage, "_attachment_storage", storage)
    payload = b"large-file\x00" * 200_000
    saved = storage.save_attachment_bytes(
        payload,
        filename="report.pdf",
        mime_type="application/pdf",
        owner_email="alice@example.com",
    )

    @asynccontextmanager
    async def no_network(_url):
        pytest.fail("An MCP file handle must not trigger an HTTP request")
        yield

    monkeypatch.setattr(drive_helpers, "_ssrf_safe_stream", no_network)
    chunks = []

    async def collect(chunk):
        chunks.append(chunk)

    size, mime = await drive_helpers._stream_url_with_validation(
        f"https://mcp.example/attachments/{saved.file_id}",
        collect,
        user_google_email="alice@example.com",
    )
    assert size == 2_200_000
    assert mime == "application/pdf"
    assert b"".join(chunks) == payload
