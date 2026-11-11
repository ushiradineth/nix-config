"""Bounded, read-only document extraction for the personal assistant."""

import json
import os
import re
import ssl
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener, HTTPSHandler

from pypdf import PdfReader

MAX_BYTES = 25 * 1024 * 1024


class DocumentError(ValueError):
    pass


def integer(request, name, default, minimum, maximum):
    value = request.get(name, default)
    if type(value) is not int or not minimum <= value <= maximum:
        raise DocumentError(f"{name} must be an integer from {minimum} to {maximum}")
    return value


def https_url(value):
    parsed = urlsplit(value)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
        raise DocumentError("Remote sources require HTTPS without URL credentials")
    return value


class HttpsRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return super().redirect_request(req, fp, code, msg, headers, https_url(newurl))


def download_pdf(url, target):
    context = ssl.create_default_context(
        cafile=os.environ.get("NIX_SSL_CERT_FILE") or os.environ.get("SSL_CERT_FILE")
    )
    opener = build_opener(HttpsRedirects(), HTTPSHandler(context=context))
    deadline = time.monotonic() + 30
    size = 0
    request = Request(https_url(url), headers={"User-Agent": "opencode-document-reader/1"})
    with opener.open(request, timeout=15) as response, target.open("xb") as output:
        os.chmod(target, 0o600)
        while chunk := response.read(64 * 1024):
            size += len(chunk)
            if size > MAX_BYTES or time.monotonic() > deadline:
                raise DocumentError("Remote PDF exceeds the 25 MiB or 30 second download limit")
            output.write(chunk)
    with target.open("rb") as downloaded:
        if not downloaded.read(5).startswith(b"%PDF-"):
            raise DocumentError("The URL did not return a PDF; use the existing service or web tools")


def command(arguments):
    result = subprocess.run(arguments, capture_output=True, timeout=25, check=False)
    if result.returncode:
        raise DocumentError(f"{Path(arguments[0]).name} could not process this PDF")
    return result.stdout.decode("utf-8")


def pdf_text(path, request, scratch):
    reader = PdfReader(path)
    if reader.is_encrypted and not reader.decrypt(""):
        raise DocumentError("PDF is password protected; an unlocked local copy is required")
    total = len(reader.pages)
    page = integer(request, "page", 1, 1, max(total, 1))
    count = integer(request, "pages", 3, 1, 3)
    mode = request.get("ocr", "auto")
    if mode not in ("auto", "always", "never"):
        raise DocumentError("ocr must be auto, always or never")
    extracted = []
    methods = []
    last = min(page + count - 1, total)
    for number in range(page, last + 1):
        text = reader.pages[number - 1].extract_text() or ""
        method = "text"
        if mode == "always" or (mode == "auto" and len(text.strip()) < 40):
            prefix = scratch / f"page-{number}"
            command([
                os.environ["OPENCODE_PDFTOPPM"], "-f", str(number), "-l", str(number),
                "-r", "180", "-scale-to", "2200", "-singlefile", "-png", str(path), str(prefix),
            ])
            text = command([os.environ["OPENCODE_TESSERACT"], str(prefix) + ".png", "stdout", "-l", "eng"])
            method = "ocr"
        methods.append({"page": number, "method": method, "empty": not bool(text.strip())})
        extracted.append(f"--- Page {number} ({method}) ---\n{text}")
    return "\n\n".join(extracted), {
        "pageCount": total, "pagesRead": methods, "nextPage": last + 1 if last < total else None,
    }


def unwrap_json(value):
    # MCP results and saved OpenCode outputs can wrap the document in a text block.
    for _ in range(5):
        if not isinstance(value, dict):
            break
        if isinstance(value.get("markdown"), str) or isinstance(value.get("plainText"), str):
            key = "markdown" if isinstance(value.get("markdown"), str) else "plainText"
            metadata = {key: value[key] for key in ("docId", "title", "revision", "exists") if key in value}
            if isinstance(metadata.get("title"), str):
                metadata["title"] = metadata["title"][:512]
            return value[key], metadata
        if isinstance(value.get("structuredContent"), dict):
            value = value["structuredContent"]
        elif isinstance(value.get("result"), dict):
            value = value["result"]
        elif isinstance(value.get("content"), list) and len(value["content"]) == 1 and isinstance(value["content"][0].get("text"), str):
            try:
                value = json.loads(value["content"][0]["text"])
            except json.JSONDecodeError:
                return value["content"][0]["text"], {}
        else:
            break
    return json.dumps(value, ensure_ascii=False, indent=2), {}


def read_document(request):
    if not isinstance(request, dict):
        raise DocumentError("Expected a document request object")
    allowed = {"source", "offset", "limit", "find", "page", "pages", "ocr"}
    if set(request) - allowed:
        raise DocumentError("Unsupported document reader argument")
    source = request.get("source")
    if not isinstance(source, str) or not source:
        raise DocumentError("source must be an absolute local path or an HTTPS PDF URL")
    offset = integer(request, "offset", 0, 0, MAX_BYTES * 4)
    limit = integer(request, "limit", 10000, 1, 12000)
    find = request.get("find")
    if find is not None and (not isinstance(find, str) or not 1 <= len(find) <= 256):
        raise DocumentError("find must be a literal phrase of 1 to 256 characters")
    with tempfile.TemporaryDirectory(prefix="opencode-document-") as temporary:
        # Leptonica fails to open ONGs through macOS's /tmp symlink.
        scratch = Path(temporary).resolve()
        remote = source.startswith("https:")
        if remote:
            path = scratch / "download.pdf"
            download_pdf(source, path)
        else:
            path = Path(source).expanduser()
            if not path.is_absolute():
                raise DocumentError("Local sources require an absolute path")
            if not path.is_file():
                raise DocumentError("Local source is unavailable or is not a regular file")
        if path.stat().st_size > MAX_BYTES:
            raise DocumentError("Local document exceeds the 25 MiB limit")
        with path.open("rb") as input_file:
            signature = input_file.read(8)
        if signature.startswith(b"%PDF-"):
            text, metadata = pdf_text(path, request, scratch)
            kind = "pdf"
        else:
            if remote:
                raise DocumentError("Remote reader accepts PDF responses only")
            with path.open("rb") as input_file:
                data = input_file.read(MAX_BYTES + 1)
            if len(data) > MAX_BYTES:
                raise DocumentError("Local document exceeds the 25 MiB limit")
            try:
                text = data.decode("utf-8")
            except UnicodeDecodeError:
                raise DocumentError("Unsupported binary format; this reader supports PDF, UTF-8 text and JSON") from None
            metadata = {}
            kind = "text"
            if path.suffix.lower() == ".json" or text.lstrip().startswith(("{", "[")):
                text, metadata = unwrap_json(json.loads(text))
                kind = "json"
        if offset > len(text):
            raise DocumentError("offset exceeds this excerpt; reset it when changing PDF pages")
        if find is not None:
            match = re.search(re.escape(find), text[offset:], flags=re.IGNORECASE)
            if match is None:
                return {"source": source, "format": kind, **metadata, "found": False, "totalChars": len(text), "text": ""}
            offset += match.start()
        end = min(offset + limit, len(text))
        return {
            "source": source, "format": kind, **metadata, "found": True,
            "offset": offset, "endOffset": end, "totalChars": len(text),
            "nextOffset": end if end < len(text) else None, "text": text[offset:end],
        }


if __name__ == "__main__":
    try:
        request = json.loads(sys.stdin.read(16384))
        print(json.dumps(read_document(request), ensure_ascii=False))
    except Exception as error:
        # Parser errors may contain document text; only known actionable failures are returned.
        message = str(error) if isinstance(error, DocumentError) else f"Document extraction failed ({type(error).__name__})"
        print(json.dumps({"error": message}), file=sys.stderr)
        sys.exit(1)
