#!/usr/bin/env python3
"""
restore_google_services.py
Reads base64 from env var GOOGLE_SERVICES_JSON_B64 and writes:
android/app/google-services.json
"""

import os, sys, base64, json, pathlib

ENV_NAME = "GOOGLE_SERVICES_JSON_B64"
OUT_PATH = "android/app/google-services.json"

def main():
    b64 = os.environ.get(ENV_NAME, "")
    if not b64:
        print(f"❌ {ENV_NAME} is not set in Codemagic Environment variables", file=sys.stderr)
        sys.exit(1)

    try:
        data = base64.b64decode(b64, validate=True)
    except Exception as e:
        print(f"❌ base64 decode failed: {e}", file=sys.stderr)
        sys.exit(2)

    pathlib.Path("android/app").mkdir(parents=True, exist_ok=True)
    with open(OUT_PATH, "wb") as f:
        f.write(data)

    # quick sanity check (no secrets printed)
    try:
        j = json.loads(data.decode("utf-8"))
        print(f"✅ Restored {OUT_PATH}; keys: {list(j.keys())[:3]}")
    except Exception as e:
        print(f"⚠️  JSON parse warning: {e}")

if __name__ == "__main__":
    main()
