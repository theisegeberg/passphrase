#!/usr/bin/env bash

# Audit script: scans the repository recursively for potentially malicious code
# around passphrase generation and sensitive data handling.
#
# What this script does:
# 1) Recursively walks all files from the current directory (.)
# 2) Excludes common build/dependency directories
# 3) Runs a series of explicit grep checks for risky behaviors
# 4) Prints the EXACT commands it runs so you can reproduce the same output
# 5) Produces a final report summary with counts
#
# Usage:
#   chmod +x audit.sh
#   ./audit.sh
#
# Reproducibility:
# - Every check prints the exact `find | xargs grep` command used.
# - If you copy/paste those commands into your shell, you’ll get the same output.

set -u

if [ -t 1 ] && [ -z "${NO_COLOR-}" ]; then
  RED=$'\033[31m'
  GREEN=$'\033[32m'
  RESET=$'\033[0m'
else
  RED=""
  GREEN=""
  RESET=""
fi

# Directories to exclude from scanning (paths are relative to repo root)
EXCLUDE_PATHS=(
  "./.git/*"
  "./.svn/*"
  "./.hg/*"
  "./.DS_Store"
  "./DerivedData/*"
  "./Pods/*"
  "./Carthage/*"
  "./.build/*"
  "./build/*"
  "./node_modules/*"
  "./.swiftpm/*"
  "./.xcodeproj/*"
  "./.xcworkspace/*"
  "./.xcarchive/*"
  "./.gitmodules"
  "./LICENSE.md"
  "./README.md"
  "./passgen.xcodeproj/xcuserdata/*"
  "./passgen.xcodeproj/project.xcworkspace/xcshareddata/*"
  "./passgen/Info.plist"
)

# Temporary output directory for per-check results
TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'audit_tmp')
TOTAL_FINDINGS=0

echo "============================================================"
echo "Passphrase Generator Audit"
echo "Start Time: $(date)"
echo "Working Dir: $(pwd)"
echo "============================================================"
echo

# Build a find command that lists files, applying excludes and optional includes.
# Arguments:
#   $1 (optional): comma-separated list of include globs (e.g., "*.sh,*.bash,*.zsh")
build_find_cmd() {
  local includes="${1:-}"
  local cmd="find . -type f"
  for p in "${EXCLUDE_PATHS[@]}"; do
    cmd+=" ! -path '$p'"
  done
  cmd+=" ! -name 'audit.sh'"

  if [ -n "$includes" ]; then
    # Build: \( -name 'pat1' -o -name 'pat2' \)
    cmd+=" \\("
    local first=1
    IFS=',' read -r -a arr <<< "$includes"
    for inc in "${arr[@]}"; do
      # trim spaces
      local inc_trimmed
      inc_trimmed=$(echo "$inc" | sed -e 's/^ *//' -e 's/ *$//')
      if [ $first -eq 0 ]; then cmd+=" -o"; fi
      cmd+=" -name '$inc_trimmed'"
      first=0
    done
    cmd+=" \\)"
  fi

  cmd+=" -print0"
  echo "$cmd"
}

# Run a grep-based check with a regex pattern against files selected by find.
# Arguments:
#   $1: check key (used for temp output file name)
#   $2: human-readable title
#   $3: description of what we are looking for
#   $4: ERE pattern for grep (-E)
#   $5 (optional): comma-separated include globs (only these files)
run_check() {
  local key="${1-}"
  local title="${2-}"
  local description="${3-}"
  local pattern="${4-}"
  local includes="${5-}"

  if [ -z "${key}" ] || [ -z "${title}" ] || [ -z "${description}" ] || [ -z "${pattern}" ]; then
    echo "------------------------------------------------------------"
    printf "%sWHAT:  Missing required arguments (key/title/description/pattern). Skipping.%s\n" "$RED" "$RESET"
    echo
    return 1
  fi

  local out_file="$TMPDIR/${key}.txt"
  local find_cmd
  find_cmd=$(build_find_cmd "$includes")

  # Count files first for transparency
  local count_cmd="$find_cmd | xargs -0 -n 1000 printf '%s\\n' | wc -l | tr -d ' '"

  echo "------------------------------------------------------------"
  echo "CHECK: $title"
  echo "WHAT:  $description"
  echo "FILES: Using find to enumerate files (excludes applied)"
  echo "RUN:   $find_cmd | xargs -0 -n 1000 printf '%s\\n' | wc -l"
  local file_count
  # shellcheck disable=SC2046
  file_count=$(eval "$count_cmd" 2>/dev/null || echo 0)
  echo "FOUND: $file_count files to scan"

  # Prepare and show the exact grep command
  local grep_cmd
  grep_cmd="$find_cmd | xargs -0 grep -n -I -H -E \"$pattern\""
  echo "RUN:   $grep_cmd"

  # Execute the command, capturing output
  eval "$grep_cmd" > "$out_file" 2>/dev/null || true

  local matches
  matches=$(wc -l < "$out_file" | tr -d ' ')
  if [ -z "$matches" ]; then matches=0; fi

  if [ "$matches" -gt 0 ]; then
    printf "%sRESULT: %s finding(s)%s\n" "$RED" "$matches" "$RESET"
    echo "OUTPUT: file:line: matched line"
    cat "$out_file"
  else
    printf "%sRESULT: No findings%s\n" "$GREEN" "$RESET"
  fi
  echo

  TOTAL_FINDINGS=$((TOTAL_FINDINGS + matches))
}

run_check \
  "network_connections" \
  "Network connections and URL usage" \
  "Looks for common network APIs, tools, and URLs that could exfiltrate data." \
  "\b(curl|wget|nc|netcat|telnet|ssh|scp|sftp)\b|\b(URLSession|NSURLConnection|URLRequest|NWConnection|WebSocketTask|CFStreamCreatePairWithSocketToHost|CFSocketCreate|AsyncHTTPClient)\b|\b(https?|wss?|ftp)://"

run_check \
  "disk_write_apis" \
  "Disk write operations (APIs)" \
  "Finds common APIs that write data to disk (Swift/ObjC/C/C++)." \
  "FileManager\.default\.createFile|try[[:space:]]+.*\.write\(to:|writeToFile|FileHandle\(forWriting|OutputStream\(toFile|NSOutputStream|fopen\([^)]*,[[:space:]]*\"[wWaA]|open\([^)]*,[[:space:]]*O_WRONLY|fwrite\(|ofstream[[:space:]]+[_A-Za-z]"

run_check \
  "shell_redirections" \
  "Shell redirections (>, >>, 2>, &>) in shell scripts" \
  "Finds shell redirection operators that may write to files or redirect output." \
  "(^|[[:space:]])(>|>>|2>|1>|&>)" \
  "*.sh,*.bash,*.zsh,*.ksh,*.fish"

run_check \
  "clipboard_access" \
  "Clipboard access (UIPasteboard/NSPasteboard)" \
  "Finds usage of clipboard APIs which may leak sensitive data." \
  "\b(UIPasteboard\.(general|unique)|NSPasteboard\.(general|generalPasteboard))\b"

run_check \
  "keychain_userdefaults" \
  "Keychain and UserDefaults storage" \
  "Finds storage APIs that may store secrets locally or in cloud-synced stores." \
  "\b(SecItemAdd|SecItemUpdate|kSecClassGenericPassword|Keychain)\b|\b(UserDefaults\.(standard\.)?set|NSUbiquitousKeyValueStore)\b"

run_check \
  "cloud_storage" \
  "Cloud storage APIs (CloudKit, remote persistence)" \
  "Finds CloudKit usage that could persist data remotely." \
  "\b(CKContainer|CKDatabase|CKRecord|CloudKit)\b"

run_check \
  "sensitive_logging" \
  "Logging calls that may include sensitive keywords" \
  "Finds logging calls that may include sensitive keywords." \
  "\b(print|NSLog|os_log|logger\.log)\b.*\b(passphrase|password|pwd|secret|token|api[_-]?key|apikey|private[_-]?key|mnemonic|seed)\b"

# Final report
echo "============================================================"
echo "FINAL REPORT"
echo "Total findings across all checks: $TOTAL_FINDINGS"
echo "============================================================"

if [ "$TOTAL_FINDINGS" -gt 0 ]; then
  printf "%sOutcome: Potentially risky patterns were found.%s\n" "$RED" "$RESET"
  echo "Action: Review the findings above. For any suspicious lines, open the file and inspect the surrounding code."
  echo
  echo "To reproduce any check manually, copy the exact 'RUN:' command printed above and execute it in your shell."
  exit 1
else
  printf "%sOutcome: No suspicious patterns were found by these checks.%s\n" "$GREEN" "$RESET"
  echo "Note: This script uses heuristics; manual review is still recommended, especially around your passphrase generator code."
  exit 0
fi

