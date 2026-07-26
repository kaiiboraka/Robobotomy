import os, re

GODOT_SCRIPTS_DIR = r"C:\Projects\Robobotomy\Scripts"


def extract_code(line: str) -> tuple[str, str]:
    """Split line into code (before unescaped #) and comment.
    Returns (code_part, comment_part). Handles all string types."""
    code = []
    comment = []
    in_single = False
    in_double = False
    in_trip_single = 0
    in_trip_double = 0

    i = 0
    while i < len(line):
        ch = line[i]

        # Escape inside regular strings — pass through
        if ch == "\\" and (in_single or in_double):
            code.append(ch)
            i += 1
            if i < len(line):
                code.append(line[i])
                i += 1
            continue

        # Triple-quote detection (outside any string)
        if not in_single and not in_double and not in_trip_single and not in_trip_double:
            if i + 2 < len(line) and line[i:i+3] == '"""':
                in_trip_double = 3
                code.append('"""')
                i += 3
                continue
            if i + 2 < len(line) and line[i:i+3] == "'''":
                in_trip_single = 3
                code.append("'''")
                i += 3
                continue

        # Inside triple-double string
        if in_trip_double:
            code.append(ch)
            if i + 2 < len(line) and line[i:i+3] == '"""':
                in_trip_double -= 1
                if in_trip_double == 0:
                    i += 3
                    continue
            i += 1
            continue

        # Inside triple-single string
        if in_trip_single:
            code.append(ch)
            if i + 2 < len(line) and line[i:i+3] == "'''":
                in_trip_single -= 1
                if in_trip_single == 0:
                    i += 3
                    continue
            i += 1
            continue

        # Regular quotes
        if ch == "'" and not in_double:
            in_single = not in_single
            code.append(ch)
            i += 1
            continue
        if ch == '"' and not in_single:
            in_double = not in_double
            code.append(ch)
            i += 1
            continue

        # Comment start (only outside strings)
        if ch == "#":
            comment = line[i:]
            break

        code.append(ch)
        i += 1

    return "".join(code), "".join(comment)


def count_bracket_line(code: str) -> tuple:
    """Count bracket delta in code, respecting strings.
    Returns (paren, bracket, brace) deltas."""
    paren = 0
    bracket = 0
    brace = 0
    in_single = False
    in_double = False
    in_trip_single = 0
    in_trip_double = 0

    i = 0
    while i < len(code):
        ch = code[i]

        if ch == "\\" and (in_single or in_double):
            i += 2
            continue

        if not in_single and not in_double and not in_trip_single and not in_trip_double:
            if i + 2 < len(code) and code[i:i+3] == '"""':
                in_trip_double = 3
                i += 3
                continue
            if i + 2 < len(code) and code[i:i+3] == "'''":
                in_trip_single = 3
                i += 3
                continue

        if in_trip_double:
            if i + 2 < len(code) and code[i:i+3] == '"""':
                in_trip_double -= 1
                if in_trip_double == 0:
                    i += 3
                    continue
            i += 1
            continue

        if in_trip_single:
            if i + 2 < len(code) and code[i:i+3] == "'''":
                in_trip_single -= 1
                if in_trip_single == 0:
                    i += 3
                    continue
            i += 1
            continue

        if ch == "'" and not in_double:
            in_single = not in_single
            i += 1
            continue
        if ch == '"' and not in_single:
            in_double = not in_double
            i += 1
            continue

        if ch == "(":
            paren += 1
        elif ch == ")":
            paren -= 1
        elif ch == "[":
            bracket += 1
        elif ch == "]":
            bracket -= 1
        elif ch == "{":
            brace += 1
        elif ch == "}":
            brace -= 1

        i += 1

    return paren, bracket, brace


def process_file(filepath: str) -> bool:
    with open(filepath, "r", encoding="utf-8", newline="") as f:
        content = f.read()

    eol = "\r\n" if "\r\n" in content else "\n"
    lines = content.split(eol)
    modified = False
    new_lines = []

    count_state = [0, 0, 0]  # paren, bracket, brace

    for line in lines:
        stripped = line

        # Blank line
        if stripped.strip() == "":
            new_lines.append(line)
            continue

        code_part, comment_part = extract_code(stripped)
        code_trimmed = code_part.rstrip()

        # Comment-only line
        if not code_trimmed:
            new_lines.append(line)
            continue

        # Count brackets on this line
        p_delta, b_delta, br_delta = count_bracket_line(code_part)

        # State before processing this line
        p_before = count_state[0]
        b_before = count_state[1]
        br_before = count_state[2]

        # Update cumulative state
        count_state[0] += p_delta
        count_state[1] += b_delta
        count_state[2] += br_delta

        # Strip existing semicolons from lines that shouldn't have them
        trimmed = code_trimmed.strip()
        if trimmed.endswith(";"):
            nosemi = trimmed[:-1].strip()
            if (nosemi == '@tool' or nosemi.startswith('class_name ') or
                re.match(r'^@export_(group|subgroup|category|tool_button)\s*\(', nosemi) or
                nosemi.endswith("\\")):
                trailing_ws = code_part[len(code_trimmed):]
                new_line = trimmed[:-1] + trailing_ws + comment_part
                new_lines.append(new_line)
                modified = True
                continue

        # Check if we should add semicolon
        should_add = True

        # @tool, @icon, @static_unload etc. (bare decorators)
        if re.match(r'^@\w+$', trimmed):
            should_add = False

        # class_name line
        elif trimmed.startswith('class_name '):
            should_add = False

        # @export_group / @export_subgroup / @export_category / @export_tool_button (bare, no var on same line)
        elif re.match(r'^@export_(group|subgroup|category|tool_button)\s*\(', trimmed):
            should_add = False

        # Header lines (ends with :)
        elif code_trimmed.endswith(":"):
            should_add = False

        # Always skip: { } ( [ , \  (backslash = GDScript line continuation)
        elif code_trimmed.endswith(("{", "}", "(", "[", ",", "\\")):
            should_add = False

        # Skip ) or ] when they close something opened on a PREVIOUS line
        elif code_trimmed.endswith(")") and p_before > 0:
            should_add = False
        elif code_trimmed.endswith("]") and b_before > 0:
            should_add = False

        # Skip if cumulative brackets are not fully balanced
        if count_state[0] != 0 or count_state[1] != 0 or count_state[2] != 0:
            should_add = False

        # Already has semicolon
        if code_trimmed.endswith(";"):
            should_add = False

        if should_add:
            trailing_ws = code_part[len(code_trimmed):]
            new_line = code_trimmed + ";" + trailing_ws + comment_part
            new_lines.append(new_line)
            modified = True
        else:
            new_lines.append(line)

    if modified:
        with open(filepath, "w", encoding="utf-8", newline="") as f:
            f.write(eol.join(new_lines))
        return True

    return False


def main():
    modified_files = []
    total_files = 0

    for root, dirs, files in os.walk(GODOT_SCRIPTS_DIR):
        for f in files:
            if f.endswith(".gd"):
                total_files += 1
                filepath = os.path.join(root, f)
                if process_file(filepath):
                    modified_files.append(filepath)

    print(f"Modified {len(modified_files)} / {total_files} .gd files:")
    for fp in modified_files:
        rel = os.path.relpath(fp, GODOT_SCRIPTS_DIR)
        print(f"  {rel}")


if __name__ == "__main__":
    main()
