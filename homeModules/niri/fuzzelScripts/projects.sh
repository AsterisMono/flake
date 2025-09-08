ROOT="${1:-$HOME/Projects}"

mapfile -t repos < <(
  find "$ROOT" -maxdepth 2 -mindepth 2 -type d -name .git -prune -exec dirname {} + 2>/dev/null \
    | sed "s|^$ROOT/||" \
    | sort -u
)

if [[ ${#repos[@]} -eq 0 ]]; then
  notify-send "No git repos found under $ROOT" || true
  exit 0
fi

selection="$(
  printf '%s\n' "${repos[@]}" \
    | fuzzel --dmenu --placeholder 'Open project: ' --lines 15
)"

[[ -n "$selection" ]] || exit 0

full_path="$ROOT/$selection"

if command -v codium >/dev/null 2>&1; then
  codium "$full_path" >/dev/null 2>&1 &
else
  notify-send "Error: 'codium' command not found. Install VS Codium or add it to PATH." >&2
  exit 1
fi

