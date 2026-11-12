# Static scanner fixtures only. Never import or execute.
import subprocess as sp
from subprocess import run as execute
import requests as http
from requests import get as fetch
import yaml as y
from yaml import load as decode, UnsafeLoader as DangerousLoader
from flask import request
import sys


def commands():
    command = request.args.get("command")
    copied = command
    # ruleid: python-external-to-shell
    sp.run(copied, shell=True)
    # ruleid: python-external-to-shell
    execute(sys.argv[1], shell=True)
    # ok: python-external-to-shell
    sp.run(["printf", request.args.get("value")], shell=False)
    # ok: python-external-to-shell
    execute(["printf", sys.argv[1]])
    # ok: python-external-to-shell
    sp.run("printf fixed", shell=True)


# ruleid: python-requests-disabled-tls
http.get("https://example.invalid", verify=False)
verification = False
# ruleid: python-requests-disabled-tls
fetch("https://example.invalid", verify=verification)
session = http.Session()
# ruleid: python-requests-disabled-tls
session.get("https://example.invalid", verify=False)
# ok: python-requests-disabled-tls
http.get("https://example.invalid", verify=True)
# ok: python-requests-disabled-tls
fetch("https://example.invalid")
# ok: python-requests-disabled-tls
session.get("https://example.invalid", verify=True)
# ok: python-requests-disabled-tls
unrelated(verify=False)

# ruleid: python-unsafe-yaml-load
y.load("data", Loader=y.Loader)
loader = DangerousLoader
# ruleid: python-unsafe-yaml-load
decode("data", Loader=loader)
# ruleid: python-unsafe-yaml-load
y.unsafe_load("data")
# ok: python-unsafe-yaml-load
y.safe_load("data")
# ok: python-unsafe-yaml-load
y.load("data", Loader=y.SafeLoader)
# ok: python-unsafe-yaml-load
y.load("data", Loader=y.CSafeLoader)
