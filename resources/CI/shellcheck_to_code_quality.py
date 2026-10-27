#!/usr/bin/env python3
"""Convert ShellCheck GCC output from stdin to GitLab Code Quality JSON."""

import hashlib
import json
import re
import sys

# path:line:column: severity: message [SC1234]
# The column is optional so that the older "gcc1" output works too.
LINE_RE = re.compile(
    r"^(?P<path>.*?):(?P<line>\d+)(?::(?P<col>\d+))?: "
    r"(?P<severity>error|warning|info|style|note): "
    r"(?P<message>.*?)\s*\[(?P<check>SC\d+)\]\s*$"
)
SEVERITY = {
    "error": "critical",
    "warning": "major",
    "style": "minor",
    "info": "minor",
    "note": "info",
}


def main():
    findings = []
    for raw in sys.stdin:
        raw = raw.rstrip("\n")
        if not raw:
            continue
        match = LINE_RE.match(raw)
        if not match:
            continue
        path = match.group("path")
        check = match.group("check")
        message = match.group("message")
        findings.append(
            {
                "description": message,
                "check_name": check,
                # Stable per finding, so GitLab can track existing findings.
                "fingerprint": hashlib.sha256(
                    f"{path}:{check}:{message}".encode()
                ).hexdigest(),
                "severity": SEVERITY.get(match.group("severity"), "minor"),
                "location": {
                    "path": path,
                    "lines": {"begin": int(match.group("line"))},
                },
            }
        )

    json.dump(findings, sys.stdout, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
