#!/usr/bin/env python3
"""
restore_google_services.py (robust)
Reads GOOGLE_SERVICES_JSON_B64 from env and writes android/app/google-services.json.
Accepts:
- pure base64 (preferred)
- base64 with newlines/quotes
- URL-safe base64 (- and _)
- values that accidentally include extra text (extracts the longest base64-looking chunk)
- raw JSON pasted by mistake (last-resort fallback)
"""
import os, sys, base64, json, pathlib, re

ENV_NAME = "GOOGLE_SERVICES_JSON_B64"
OUT_PATH = "android/app/google-services.json"

def try_decode_b64(s: str):
    # normal base64 first
    try:
        return base64.b64decode(s, validate=True)
    except Exception:
        pass
    # URL-safe variant
    try:
        ss = s.replace('-', '+').replace('_', '/')
        # pad if needed
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

    # strip quotes/whitespace
    val = raw.strip().strip('"').strip("'")

    # 1) direct base64 decode
    data = try_decode_b64(val)

    # 2) if failed, try to extract the longest base64-looking token
    if data is None:
        tokens = re.findall(r"[A-Za-z0-9_\/\-\+=]{20,}", val)  # likely base64 segments
        tokens.sort(key=len, reverse=True)
        for t in tokens:
            data = try_decode_b64(t)
            if data:
                print(f"[INFO] Decoded from longest base64-like segment (len={len(t)})")
                break

    # 3) if still None, maybe the user pasted raw JSON
    if data is None:
        try:
            j = json.loads(val)
            data = json.dumps(j, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
            print("[INFO] Value parsed as raw JSON (not base64).")
        except Exception:
            print("❌ base64 decode failed and value is not valid JSON.", file=sys.stderr)
            sys.exit(2)

    # quick sanity check that it is JSON and looks like google-services
    try:
        j = json.loads(data.decode("utf-8"))
        if not isinstance(j, dict) or "project_info" not in j:
            print("⚠️  Decoded JSON does not contain 'project_info' — double-check your secret.", file=sys.stderr)
        else:
            print("✅ Decoded JSON ok; keys:", list(j.keys())[:3])
    except Exception as e:
        print(f"⚠️  Decoded payload is not JSON: {e}", file=sys.stderr)

    pathlib.Path("android/app").mkdir(parents=True, exist_ok=True)
    with open(OUT_PATH, "wb") as f:
        f.write(data)
    print(f"✅ Wrote {OUT_PATH} ({len(data)} bytes)")

if __name__ == "__main__":
    main()
