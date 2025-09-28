#!/usr/bin/env python3
"""
restore_google_services.py (robust)
Reads GOOGLE_SERVICES_JSON_B64 from env and writes android/app/google-services.json.
Accepts base64 (with stray whitespace/newlines) or raw JSON as a fallback.
"""
import os, sys, base64, json, pathlib, re

ENV_NAME = "GOOGLE_SERVICES_JSON_B64"
OUT_PATH = "android/app/google-services.json"

def try_decode_b64(s: str):
    try:
        return base64.b64decode(s, validate=True)
    except Exception:
        pass
    try:
        ss = s.replace('-', '+').replace('_', '/')
        pad = (-len(ss)) % 4
        ss = ss + ('=' * pad)
        return base64.b64decode(ss)
    except Exception:
        return None

def main():
    raw = os.environ.get(ENV_NAME, "")
    if not raw:
        print(f"❌ {ENV_NAME} not set/empty", file=sys.stderr)
        sys.exit(1)

    val = raw.strip().strip('"').strip("'")
    data = try_decode_b64(val)

    if data is None:
        tokens = re.findall(r"[A-Za-z0-9_\/\-\+=]{20,}", val)
        tokens.sort(key=len, reverse=True)
        for t in tokens:
            data = try_decode_b64(t)
            if data:
                print(f"[INFO] Decoded from longest base64-like segment (len={len(t)})")
                break

    if data is None:
        try:
            j = json.loads(val)
            data = json.dumps(j, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
            print("[INFO] Value parsed as raw JSON (not base64).")
        except Exception:
            print("❌ base64 decode failed and value is not valid JSON.", file=sys.stderr)
            sys.exit(2)

    try:
        j = json.loads(data.decode("utf-8"))
        if "project_info" in j:
            print("✅ Decoded JSON ok; keys:", list(j.keys())[:3])
        else:
            print("⚠️  JSON lacks 'project_info' — double-check secret.", file=sys.stderr)
    except Exception as e:
        print(f"⚠️  Decoded payload not JSON: {e}", file=sys.stderr)

    pathlib.Path("android/app").mkdir(parents=True, exist_ok=True)
    with open(OUT_PATH, "wb") as f:
        f.write(data)
    print(f"✅ Wrote {OUT_PATH} ({len(data)} bytes)")

if __name__ == "__main__":
    main()
