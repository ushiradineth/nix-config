# Build context: google_workspace_mcp at 2e9e9e785d30abaf89cf181c548d172b09ed0150
# with file-handles.patch applied. Upstream is MIT-licensed; its licence stays in /app.
# Copy test_account_file_handles.py into tests/gdrive/ for the regression suite.
FROM ghcr.io/taylorwilsdon/google_workspace_mcp:sha-2e9e9e7@sha256:52ce59e89e0dbc45725e78b6600c37dfacd529480a35f784eb483582f0f61512

COPY --chown=app:app core/attachment_storage.py core/file_handles.py core/server.py /app/core/
COPY --chown=app:app auth/oauth_callback_server.py /app/auth/
COPY --chown=app:app gdrive/drive_helpers.py gdrive/drive_tools.py /app/gdrive/
COPY --chown=app:app gmail/gmail_tools.py /app/gmail/
COPY --chown=app:app gchat/chat_tools.py /app/gchat/

LABEL org.opencontainers.image.source="https://github.com/taylorwilsdon/google_workspace_mcp" \
      org.opencontainers.image.revision="2e9e9e785d30abaf89cf181c548d172b09ed0150" \
      org.opencontainers.image.description="Account-bound expiring file handles for shared Google Workspace transfers"
