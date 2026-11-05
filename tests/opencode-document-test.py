import hashlib
import importlib.util
import io
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image, ImageDraw, ImageFont
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("reader", ROOT / "scripts/opencode-document.py")
reader = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(reader)


class Documents(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_single_line_json_seeks_the_current_section_and_retains_revision(self):
        path = self.root / "note.json"
        current = "START HERE — Current profile\nConfirmed profit 123456.78\n"
        document = {"docId": "existing-note", "revision": "a" * 64, "title": "Profile",
                    "blocks": [{"text": "redundant copy"}],
                    "plainText": "old notes " * 15000 + current}
        path.write_text(json.dumps({"result": {"content": [{"type": "text", "text": json.dumps(document)}]}}))
        original = path.read_bytes()
        result = reader.read_document({"source": str(path), "find": "START HERE"})
        self.assertEqual(result["text"], current)
        self.assertEqual(result["revision"], "a" * 64)
        self.assertGreater(result["offset"], 65536)
        self.assertIsNone(result["nextOffset"])
        self.assertNotIn("blocks", result)
        self.assertEqual(path.read_bytes(), original)

    def test_literal_search_and_continuation_do_not_skip_or_repeat_text(self):
        path = self.root / "export.json"
        text = "Intro\n" + "[Literal.*] ☀\n" + "café 123.45\n" * 7000
        path.write_text(json.dumps({"markdown": text}))
        first = reader.read_document({"source": str(path), "find": "[literal.*]", "limit": 22})
        tail = reader.read_document({"source": str(path), "offset": first["nextOffset"], "limit": 12})
        self.assertEqual(first["text"] + tail["text"], text[first["offset"]:tail["endOffset"]])
        missing = reader.read_document({"source": str(path), "find": "absent"})
        self.assertFalse(missing["found"])
        self.assertEqual(missing["text"], "")
        self.assertLessEqual(len(reader.read_document({"source": str(path)})["text"]), 10000)

    def make_pdf(self, name="text.pdf", scan=False):
        path = self.root / name
        pdf = canvas.Canvas(str(path), pagesize=(600, 800))
        if scan:
            image = Image.new("RGB", (1700, 500), "white")
            draw = ImageDraw.Draw(image)
            font = ImageFont.truetype(os.environ["OPENCODE_DOCUMENT_TEST_FONT"], 52)
            draw.text((60, 120), "Taxable profit 123456.78", fill="black", font=font)
            png = self.root / "scan.png"
            image.save(png)
            pdf.drawImage(str(png), 20, 450, width=560, height=165)
            pdf.showPage()
        else:
            for number in range(1, 6):
                pdf.drawString(40, 700, f"Page {number}: Confirmed taxable profit 123456.78 and payment evidence.")
                pdf.showPage()
        pdf.save()
        return path

    def test_text_pdf_is_paged_and_original_is_unchanged(self):
        path = self.make_pdf()
        original = hashlib.sha256(path.read_bytes()).digest()
        first = reader.read_document({"source": str(path)})
        self.assertEqual(first["pageCount"], 5)
        self.assertEqual(first["nextPage"], 4)
        self.assertEqual([page["method"] for page in first["pagesRead"]], ["text"] * 3)
        self.assertIn("123456.78", first["text"])
        self.assertNotIn("Page 4:", first["text"])
        last = reader.read_document({"source": str(path), "page": 4})
        self.assertIsNone(last["nextPage"])
        self.assertIn("Page 5:", last["text"])
        self.assertEqual(hashlib.sha256(path.read_bytes()).digest(), original)

    def test_scanned_pdf_uses_real_local_ocr(self):
        path = self.make_pdf("scan.pdf", scan=True)
        self.assertFalse(PdfReader(path).pages[0].extract_text().strip())
        result = reader.read_document({"source": str(path)})
        self.assertEqual(result["pagesRead"], [{"page": 1, "method": "ocr", "empty": False}])
        self.assertIn("123456.78", result["text"])
        self.assertIn("Taxable profit", result["text"])
        skipped = reader.read_document({"source": str(path), "ocr": "never"})
        self.assertTrue(skipped["pagesRead"][0]["empty"])
        forced = reader.read_document({"source": str(self.make_pdf()), "pages": 1, "ocr": "always"})
        self.assertEqual(forced["pagesRead"][0]["method"], "ocr")
        self.assertIn("123456.78", forced["text"])
        env = {key: value for key, value in os.environ.items() if key not in ("TMPDIR", "TMP", "TEMP")}
        result = subprocess.run(
            [os.environ["OPENCODE_DOCUMENT_TEST_BINARY"]],
            input=json.dumps({"source": str(path), "pages": 1}),
            text=True, capture_output=True, env=env,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("123456.78", json.loads(result.stdout)["text"])

    def test_https_pdf_downloads_privately_and_rejects_other_protocols(self):
        pdf = self.make_pdf().read_bytes()
        class Opener:
            def open(self, request, timeout):
                self.request = request
                return io.BytesIO(pdf)
        opener = Opener()
        with patch.object(reader, "build_opener", return_value=opener):
            result = reader.read_document({"source": "https://official.example/circular.pdf", "pages": 1})
        self.assertIn("123456.78", result["text"])
        self.assertNotIn("Authorization", opener.request.headers)
        self.assertNotIn("Cookie", opener.request.headers)
        for url in ("http://example.com/file.pdf", "file:///etc/passwd", "https://user:secret@example.com/file.pdf"):
            with self.assertRaises(ValueError):
                reader.https_url(url)
        with self.assertRaises(ValueError):
            reader.HttpsRedirects().redirect_request(None, None, 302, "redirect", {}, "http://example.com/")

    def test_locked_pdf_and_invalid_requests_are_specific_failures(self):
        encrypted = self.root / "locked.pdf"
        writer = PdfWriter()
        writer.add_blank_page(width=600, height=800)
        writer.encrypt("fixture-password")
        writer.write(encrypted)
        with self.assertRaisesRegex(ValueError, "password protected"):
            reader.read_document({"source": str(encrypted)})
        path = self.root / "note.txt"
        path.write_text("small text")
        for extra in ({"pages": 4}, {"limit": 12001}, {"offset": -1}, {"offset": True}, {"find": ""}, {"command": "touch something"}):
            with self.assertRaises(ValueError):
                reader.read_document({"source": str(self.make_pdf()), **extra})
        with self.assertRaisesRegex(ValueError, "absolute"):
            reader.read_document({"source": "note.txt"})
        with self.assertRaisesRegex(ValueError, "offset exceeds"):
            reader.read_document({"source": str(path), "offset": 100})

    def test_packaged_cli_treats_shell_metacharacters_as_filename_bytes(self):
        path = self.root / "literal $(touch oops) `uname`.json"
        path.write_text(json.dumps({"markdown": "Verified 123.45"}))
        result = subprocess.run([os.environ["OPENCODE_DOCUMENT_TEST_BINARY"]], input=json.dumps({"source": str(path)}), text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout)["text"], "Verified 123.45")
        self.assertEqual(result.stderr, "")
        self.assertFalse((self.root / "oops").exists())


if __name__ == "__main__":
    unittest.main()
