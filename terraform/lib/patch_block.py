#!/usr/bin/env python3
"""Replace a marked paste block in a source file with a paste file's content.

Used by per-challenge `solve-workstation` scripts to bring a skipped learner
to the same end-state a successful learner reaches by pasting manually.

Blocks are delimited by marker comments (see app/server.py and
app/static/app.js):

    # ───────────────────────────────────────────────
    # <name> paste block — optional description...
    # ...
    # ───────────────────────────────────────────────
    <stub or previously pasted code>
    # ─── End <name> paste block ────────────────────

The block starts at the decorative line above the line containing
"<name> paste block" and ends at the line containing "End <name> paste
block". Comment syntax (# or //) doesn't matter — matching is by substring.

Paste files must include their own begin/end marker lines with the same
<name>, so a later challenge can re-anchor and replace the same block.
Running twice with the same paste is a no-op by construction.

Usage: patch_block.py <target-file> <block-name> <paste-file>
"""
import pathlib
import sys


def _is_comment(line: str) -> bool:
    stripped = line.lstrip()
    return stripped.startswith("#") or stripped.startswith("//")


def find_block(lines: list[str], name: str) -> tuple[int, int]:
    """Return (start, end) line indexes of the block, inclusive.

    Anchors only on comment lines, so prose or strings that mention a block
    by name can't be mistaken for the marker.
    """
    begin_needle = f"{name} paste block"
    end_needle = f"End {name} paste block"
    begin = end = -1
    for i, line in enumerate(lines):
        if not _is_comment(line):
            continue
        if end_needle in line:
            end = i
            break
        if begin == -1 and begin_needle in line:
            # The decorative ─ line sits directly above the name line.
            begin = i - 1 if i > 0 and "─" in lines[i - 1] else i
    if begin == -1 or end == -1 or end < begin:
        raise SystemExit(
            f"ERROR: paste block '{name}' not found (begin={begin}, end={end})"
        )
    return begin, end


def main() -> int:
    if len(sys.argv) != 4:
        print(__doc__, file=sys.stderr)
        return 2

    target = pathlib.Path(sys.argv[1])
    name = sys.argv[2]
    paste = pathlib.Path(sys.argv[3]).read_text()

    # A paste without its own markers would make the next application
    # duplicate content instead of replacing it. Refuse early.
    if f"{name} paste block" not in paste or f"End {name} paste block" not in paste:
        raise SystemExit(
            f"ERROR: paste file {sys.argv[3]} does not carry the "
            f"'{name}' begin/end markers"
        )

    lines = target.read_text().splitlines(keepends=True)
    begin, end = find_block(lines, name)

    if not paste.endswith("\n"):
        paste += "\n"
    new_text = "".join(lines[:begin]) + paste + "".join(lines[end + 1:])
    target.write_text(new_text)
    print(f"Patched block '{name}' in {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
