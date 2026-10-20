#!/usr/bin/env python3
"""Convert shellcheck output into GitLab's Code Quality report format.

Reads shellcheck's "gcc" format on stdin and writes a
gl-code-quality-report.json compatible JSON array on stdout.

    shellcheck --format=gcc -f gcc $(find . -name '*.sh') | \
        python3 shellcheck2codequality.py > gl-code-quality-report.json

The report format is documented at
https://docs.gitlab.com/ci/testing/code_quality/
"""
import hashlib
import json
import re
import sys

# path:line:column: severity: message [SC1234]
# The column is optional so that the older "gcc1" output works too.
# shellcheck severities are error, warning, info, style and note.
LINE_RE = re.compile(
    r"^(?P<path>.*?):(?P<line>\d+)(?::(?P<col>\d+))?: "
    r"(?P<severity>error|warning|info|style|note): "
    r"(?P<message>.*?)\s*\[(?P<check>SC\d+)\]\s*$")

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
        m = LINE_RE.match(raw)
        if not m:
            continue
        path = m.group("path")
        line = int(m.group("line"))
        check = m.group("check")
        message = m.group("message")
        findings.append({
            "description": message,
            "check_name": check,
            # Stable per finding, so GitLab can tell new from pre-existing.
            "fingerprint": hashlib.sha256(
                f"{path}:{check}:{message}".encode()).hexdigest(),
            "severity": SEVERITY.get(m.group("severity"), "minor"),
            "location": {
                "path": path,
                "lines": {"begin": line},
            },
        })

    json.dump(findings, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
