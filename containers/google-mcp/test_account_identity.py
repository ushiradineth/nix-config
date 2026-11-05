"""No credentials/network: exercise the gateway identity contract with a fake provider."""

import time
import unittest
from types import SimpleNamespace

from account_identity import authenticated_account


class Provider:
    def __init__(self, claims=None):
        self.calls = []
        self.token = SimpleNamespace(
            claims=claims or {"email": "fixture@example.invalid", "sub": "12345", "email_verified": True},
            subject="12345",
            expires_at=int(time.time()) + 3600,
        )

    async def load_access_token(self, token):
        self.calls.append(token)
        return self.token


class AccountIdentityTest(unittest.IsolatedAsyncioTestCase):
    async def test_only_provider_verified_bearer_identity_is_returned(self):
        provider = Provider()
        result = await authenticated_account(provider, "GET", "", ["Bearer synthetic-token"])
        self.assertEqual(result, {
            "version": 1,
            "account": "fixture@example.invalid",
            "subject": "12345",
            "emailVerified": True,
            "expiresAt": provider.token.expires_at,
        })
        self.assertEqual(provider.calls, ["synthetic-token"])
        self.assertNotIn("synthetic-token", str(result))

    async def test_absent_duplicate_cookie_query_or_non_get_authority_is_rejected(self):
        for method, query, headers in [
            ("GET", "", []),
            ("GET", "", ["Bearer one", "Bearer two"]),
            ("GET", "", ["Cookie personal-session"]),
            ("GET", "access_token=synthetic-token", ["Bearer synthetic-token"]),
            ("POST", "", ["Bearer synthetic-token"]),
            ("GET", "", ["Bearer token\nheader"]),
            ("GET", "", ["Bearer " + "x" * 8193]),
        ]:
            provider = Provider()
            with self.subTest(method=method, query=query, headers=len(headers)):
                with self.assertRaisesRegex(PermissionError, "Account identity unavailable"):
                    await authenticated_account(provider, method, query, headers)
                self.assertEqual(provider.calls, [])

    async def test_expired_invalid_unverified_or_missing_principal_is_rejected(self):
        for change in [
            {"token": None},
            {"claims": {"email": "fixture@example.invalid", "sub": "12345", "email_verified": False}},
            {"claims": {"email": "fixture@example.invalid", "sub": "12345", "email_verified": "false"}},
            {"claims": {"email": "fixture@example.invalid", "sub": "12345", "email_verified": 1}},
            {"claims": {"email": "malformed", "sub": "12345", "email_verified": True}},
            {"subject": "foreign"},
            {"expires_at": 1},
            {"expires_at": None},
        ]:
            provider = Provider()
            if "token" in change:
                provider.token = change["token"]
            else:
                for key, value in change.items():
                    setattr(provider.token, key, value)
            with self.subTest(change=list(change)):
                with self.assertRaisesRegex(PermissionError, "Account identity unavailable"):
                    await authenticated_account(provider, "GET", "", ["Bearer synthetic-token"])


if __name__ == "__main__":
    unittest.main()
