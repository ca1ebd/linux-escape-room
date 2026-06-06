#!/usr/bin/env python3
"""Generate a deterministic ~7000-line access log with one anomalous line.

The anomaly: HTTP status 418 (unused in normal traffic) with a hidden field
at the end of the line that is the fragment for puzzle 5.
The anomaly line appears at a fixed offset (line 4242) so the output is
reproducible across builds without relying on random.
"""

import sys

FRAGMENT = "ECHO"
ANOMALY_LINE = 4242
TOTAL_LINES = 7000

# Fixed pool of realistic-looking log entries (cycling)
NORMAL_ENTRIES = [
    '10.0.0.1 - - [01/Jun/2024:10:00:00 +0000] "GET /index.html HTTP/1.1" 200 1024 "-" "Mozilla/5.0"',
    '10.0.0.2 - - [01/Jun/2024:10:00:01 +0000] "GET /style.css HTTP/1.1" 200 512 "-" "Mozilla/5.0"',
    '10.0.0.3 - - [01/Jun/2024:10:00:02 +0000] "POST /api/login HTTP/1.1" 200 256 "-" "curl/7.68"',
    '10.0.0.4 - - [01/Jun/2024:10:00:03 +0000] "GET /favicon.ico HTTP/1.1" 404 128 "-" "Chrome/90"',
    '10.0.0.5 - - [01/Jun/2024:10:00:04 +0000] "GET /robots.txt HTTP/1.1" 200 64 "-" "Googlebot/2.1"',
    '10.0.0.6 - - [01/Jun/2024:10:00:05 +0000] "GET /images/logo.png HTTP/1.1" 301 0 "-" "Firefox/88"',
    '10.0.0.7 - - [01/Jun/2024:10:00:06 +0000] "GET /api/status HTTP/1.1" 200 32 "-" "Python/3.9"',
    '10.0.0.8 - - [01/Jun/2024:10:00:07 +0000] "DELETE /api/session HTTP/1.1" 200 16 "-" "curl/7.68"',
    '10.0.0.9 - - [01/Jun/2024:10:00:08 +0000] "GET /docs/ HTTP/1.1" 200 2048 "-" "Mozilla/5.0"',
    '10.0.0.10 - - [01/Jun/2024:10:00:09 +0000] "OPTIONS /api/ HTTP/1.1" 200 0 "-" "curl/7.68"',
]

# The anomaly: status 418, extra fragment field at the end
ANOMALY = (
    f'10.13.37.42 - - [01/Jun/2024:03:14:15 +0000] '
    f'"GET /api/teapot HTTP/1.1" 418 0 "-" "python-requests/2.25" {FRAGMENT}'
)


def main(output_path: str = "/srv/logs/access.log") -> None:
    import os
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        for i in range(1, TOTAL_LINES + 1):
            if i == ANOMALY_LINE:
                f.write(ANOMALY + "\n")
            else:
                f.write(NORMAL_ENTRIES[(i - 1) % len(NORMAL_ENTRIES)] + "\n")


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "/srv/logs/access.log"
    main(path)
    print(f"Generated {TOTAL_LINES} lines → {path}")
