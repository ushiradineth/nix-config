"""Minimal authenticated-account contract for the app-owned Google MCP client.

The provider performs proxy JWT/JTI and upstream Google token verification. Never
decode a client JWT here, accept an account selector or consult a cookie/session.
"""

import asyncio
import re
import time


async def authenticated_account(provider, method, query, authorization_headers):
    try:
        if provider is None or method != "GET" or query or len(authorization_headers) != 1:
            raise PermissionError
        header = authorization_headers[0]
        if not isinstance(header, str) or not re.fullmatch(r"(?i:Bearer) [!-~]{1,8192}", header):
            raise PermissionError
        token = await asyncio.wait_for(provider.load_access_token(header[7:]), timeout=5)
        if token is None:
            raise PermissionError
        claims = token.claims
        if not isinstance(claims, dict):
            raise PermissionError
        email, subject, verified = claims.get("email"), claims.get("sub"), claims.get("email_verified")
        if not (verified is True or verified == "true"):
            raise PermissionError
        if not isinstance(email, str) or len(email) > 254 or not re.fullmatch(r"[^\s@\x00-\x1f]+@[^\s@\x00-\x1f]+\.[^\s@\x00-\x1f]+", email):
            raise PermissionError
        if not isinstance(subject, str) or not re.fullmatch(r"[0-9]{1,128}", subject) or token.subject != subject:
            raise PermissionError
        expiry = token.expires_at
        if type(expiry) is not int or expiry <= time.time() + 1:
            raise PermissionError
        return {"version": 1, "account": email, "subject": subject, "emailVerified": True, "expiresAt": expiry}
    except Exception:
        # No bearer, upstream exception, token metadata or account details in errors/logs.
        raise PermissionError("Account identity unavailable") from None
