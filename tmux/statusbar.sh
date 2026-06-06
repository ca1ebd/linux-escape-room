#!/bin/bash
# Render the status line — timer only.
python3 -c "
import sys
sys.path.insert(0, '/game/engine')
try:
    import state as s, timer as t
    st = s.load()
    print(t.format_timer(st))
except Exception:
    print('')
" 2>/dev/null
