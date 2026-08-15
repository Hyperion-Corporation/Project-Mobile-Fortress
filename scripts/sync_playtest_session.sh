#!/usr/bin/env bash
# Merge a DT7 export (user://playtest_sessions.json from a device) into the
# dashboard file PlaytestNotesView already reads. One command, no hand-edit.
set -euo pipefail

usage() {
  echo "usage: $0 <exported-playtest-sessions.json> [dest]" >&2
  echo "  dest defaults to docs/website/public/dashboard-data/playtest_sessions.json" >&2
  exit 2
}

[[ $# -ge 1 ]] || usage
SRC=$1
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${2:-$ROOT/docs/website/public/dashboard-data/playtest_sessions.json}"

if [[ ! -f "$SRC" ]]; then
  echo "sync_playtest_session: source not found: $SRC" >&2
  exit 1
fi
mkdir -p "$(dirname "$DEST")"

python3 - "$SRC" "$DEST" <<'PY'
import json
import sys

src_path, dest_path = sys.argv[1], sys.argv[2]

with open(src_path, encoding="utf-8") as f:
    src = json.load(f)

try:
    with open(dest_path, encoding="utf-8") as f:
        dest = json.load(f)
except FileNotFoundError:
    dest = {}

if not isinstance(src, dict):
    raise SystemExit("source is not a JSON object")
if not isinstance(dest, dict):
    dest = {}

dest.setdefault("gate", "VS10")
dest.setdefault("sessions_required", 2)
dest.setdefault("gate_decision", None)
if not isinstance(dest.get("sessions"), list):
    dest["sessions"] = []


def dashboard_session(session):
    notes = str(session.get("notes") or "")
    lines = [notes] if notes else []
    for event in session.get("events") or []:
        if not isinstance(event, dict):
            continue
        line = f"{event.get('iso', '')} — {event.get('label', 'mark')}"
        phase = event.get("phase") or ""
        if phase:
            line += f" [{phase}]"
        extra = event.get("note") or ""
        if extra:
            line += f" · {extra}"
        lines.append(line)
    verdict = session.get("verdict") or "needs_work"
    if verdict not in ("shows_promise", "needs_work", "no"):
        verdict = "needs_work"
    return {
        "id": str(session.get("id") or ""),
        "date": str(session.get("date") or ""),
        "tester": str(session.get("tester") or "tester"),
        "platform": str(session.get("platform") or ""),
        "build_commit": str(session.get("build_commit") or "unknown"),
        "hard_criteria_pass": bool(session.get("hard_criteria_pass", False)),
        "art_criteria_pass": bool(session.get("art_criteria_pass", False)),
        "verdict": verdict,
        "notes": "\n".join(lines),
    }

index = {}
out_sessions = list(dest["sessions"])
for i, existing in enumerate(out_sessions):
    if isinstance(existing, dict) and existing.get("id"):
        index[str(existing["id"])] = i

for session in src.get("sessions") or []:
    if not isinstance(session, dict):
        continue
    mapped = dashboard_session(session)
    sid = mapped.get("id") or ""
    if sid and sid in index:
        out_sessions[index[sid]] = mapped
    else:
        out_sessions.append(mapped)
        if sid:
            index[sid] = len(out_sessions) - 1

dest["sessions"] = out_sessions
with open(dest_path, "w", encoding="utf-8") as f:
    json.dump(dest, f, indent="\t", ensure_ascii=False)
    f.write("\n")
print(f"synced {len(out_sessions)} session(s) → {dest_path}")
PY
