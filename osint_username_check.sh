#!/usr/bin/env bash
# osint_username_check.sh — Public username enumeration across platforms
# Usage: ./osint_username_check.sh [options] "username1" "username2" ...
# Only checks PUBLIC profiles — no private data, no auth, no scraping behind logins.
#
# Options:
#   -j, --json       Output JSON (to stdout or file with -o)
#   -c, --csv        Output CSV (to stdout or file with -o)
#   -o, --output     Output file (for JSON/CSV)
#   -d, --delay N    Delay between requests in seconds (default: 1)
#   -t, --timeout N  Request timeout in seconds (default: 10)
#   -h, --help       Show this help
#
# Examples:
#   ./osint_username_check.sh torvalds
#   ./osint_username_check.sh -j -o results.json torvalds gavin
#   ./osint_username_check.sh -c -o results.csv user1 user2

set -euo pipefail

USER_AGENT="OSINT-Username-Check/1.0 (+https://github.com/your-repo)"
DELAY=1
TIMEOUT=10
OUTPUT_FORMAT="text"
OUTPUT_FILE=""

PLATFORMS=(
    "GitHub:https://github.com/%s"
    "GitLab:https://gitlab.com/%s"
    "Twitter/X:https://x.com/%s"
    "Instagram:https://instagram.com/%s"
    "Reddit:https://reddit.com/user/%s"
    "LinkedIn:https://linkedin.com/in/%s"
    "Medium:https://medium.com/@%s"
    "Dev.to:https://dev.to/%s"
    "HackerNews:https://news.ycombinator.com/user?id=%s"
    "Keybase:https://keybase.io/%s"
    "Telegram:https://t.me/%s"
    "YouTube:https://youtube.com/@%s"
    "Twitch:https://twitch.tv/%s"
    "TikTok:https://tiktok.com/@%s"
    "Pinterest:https://pinterest.com/%s"
    "SoundCloud:https://soundcloud.com/%s"
    "Bandcamp:https://%s.bandcamp.com"
    "Steam:https://steamcommunity.com/id/%s"
    "NPM:https://npmjs.com/~%s"
    "PyPI:https://pypi.org/user/%s"
    "Crates.io:https://crates.io/users/%s"
    "Docker Hub:https://hub.docker.com/u/%s"
    "Product Hunt:https://producthunt.com/@%s"
    "AngelList:https://angel.co/%s"
    "CodePen:https://codepen.io/%s"
    "Replit:https://replit.com/@%s"
    "GitHub Gist:https://gist.github.com/%s"
    "Pastebin:https://pastebin.com/u/%s"
    "Bitbucket:https://bitbucket.org/%s/"
    "SourceForge:https://sourceforge.net/u/%s"
    "Launchpad:https://launchpad.net/~%s"
    "GitHub Pages:https://%s.github.io"
    "GitLab Pages:https://%s.gitlab.io"
    "Netlify:https://%s.netlify.app"
    "Vercel:https://%s.vercel.app"
    "Heroku:https://%s.herokuapp.com"
    "Surge:https://%s.surge.sh"
    "Firebase:https://%s.web.app"
    "GitBook:https://%s.gitbook.io"
    "Notion:https://%s.notion.site"
    "Obsidian:https://publish.obsidian.md/%s"
)

check_url() {
    local platform="$1"
    local url="$2"
    local username="$3"

    local formatted_url
    formatted_url=$(printf "$url" "$username")

    # Use HEAD request first (faster), fall back to GET
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "User-Agent: $USER_AGENT" \
        -H "Accept: text/html,application/xhtml+xml" \
        --max-time "$TIMEOUT" \
        --head "$formatted_url" 2>/dev/null || echo "000")

    case "$http_code" in
        200|301|302|307|308)
            echo "  ✓ FOUND: $platform → $formatted_url"
            return 0
            ;;
        404)
            echo "  ✗ Not found: $platform"
            return 1
            ;;
        403|429)
            echo "  ⚠ Blocked/Rate-limited: $platform (HTTP $http_code)"
            return 2
            ;;
        000)
            echo "  ✗ Connection failed: $platform"
            return 2
            ;;
        *)
            echo "  ? HTTP $http_code: $platform → $formatted_url"
            return 2
            ;;
    esac
}

# ── Output functions ──

json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

output_json() {
    local username="$1"
    local platform="$2"
    local url="$3"
    local status="$4"  # found, not_found, error
    local http_code="$5"

    printf '{"username":"%s","platform":"%s","url":"%s","status":"%s","http_code":%s}\n' \
        "$(json_escape "$username")" \
        "$(json_escape "$platform")" \
        "$(json_escape "$url")" \
        "$(json_escape "$status")" \
        "$http_code"
}

output_csv() {
    local username="$1"
    local platform="$2"
    local url="$3"
    local status="$4"
    local http_code="$5"

    # CSV with quoting
    printf '"%s","%s","%s","%s",%s\n' \
        "$(json_escape "$username")" \
        "$(json_escape "$platform")" \
        "$(json_escape "$url")" \
        "$(json_escape "$status")" \
        "$http_code"
}

check_url_json() {
    local platform="$1"
    local url="$2"
    local username="$3"

    local formatted_url
    formatted_url=$(printf "$url" "$username")

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "User-Agent: $USER_AGENT" \
        -H "Accept: text/html,application/xhtml+xml" \
        --max-time "$TIMEOUT" \
        --head "$formatted_url" 2>/dev/null || echo "000")

    case "$http_code" in
        200|301|302|307|308)
            output_json "$username" "$platform" "$formatted_url" "found" "$http_code"
            return 0
            ;;
        404)
            output_json "$username" "$platform" "$formatted_url" "not_found" "$http_code"
            return 1
            ;;
        403|429)
            output_json "$username" "$platform" "$formatted_url" "blocked" "$http_code"
            return 2
            ;;
        000)
            output_json "$username" "$platform" "$formatted_url" "error" "$http_code"
            return 2
            ;;
        *)
            output_json "$username" "$platform" "$formatted_url" "unknown" "$http_code"
            return 2
            ;;
    esac
}

check_url_csv() {
    local platform="$1"
    local url="$2"
    local username="$3"

    local formatted_url
    formatted_url=$(printf "$url" "$username")

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "User-Agent: $USER_AGENT" \
        -H "Accept: text/html,application/xhtml+xml" \
        --max-time "$TIMEOUT" \
        --head "$formatted_url" 2>/dev/null || echo "000")

    case "$http_code" in
        200|301|302|307|308)
            output_csv "$username" "$platform" "$formatted_url" "found" "$http_code"
            return 0
            ;;
        404)
            output_csv "$username" "$platform" "$formatted_url" "not_found" "$http_code"
            return 1
            ;;
        403|429)
            output_csv "$username" "$platform" "$formatted_url" "blocked" "$http_code"
            return 2
            ;;
        000)
            output_csv "$username" "$platform" "$formatted_url" "error" "$http_code"
            return 2
            ;;
        *)
            output_csv "$username" "$platform" "$formatted_url" "unknown" "$http_code"
            return 2
            ;;
    esac
}

check_username_text() {
    local username="$1"
    echo
    echo "═══════════════════════════════════════════"
    echo "  Checking: $username"
    echo "═══════════════════════════════════════════"

    local found=0
    local blocked=0

    for entry in "${PLATFORMS[@]}"; do
        IFS=':' read -r platform url <<< "$entry"
        check_url "$platform" "$url" "$username"
        case $? in
            0) ((found++)) ;;
            2) ((blocked++)) ;;
        esac
        sleep "$DELAY"
    done

    echo
    echo "  Summary: $found found, $blocked errors/blocked"
}

check_username_json() {
    local username="$1"

    for entry in "${PLATFORMS[@]}"; do
        IFS=':' read -r platform url <<< "$entry"
        check_url_json "$platform" "$url" "$username"
        sleep "$DELAY"
    done
}

check_username_csv() {
    local username="$1"

    for entry in "${PLATFORMS[@]}"; do
        IFS=':' read -r platform url <<< "$entry"
        check_url_csv "$platform" "$url" "$username"
        sleep "$DELAY"
    done
}

# ── Argument parsing ──

show_help() {
    sed -n '2,22p' "$0" | sed 's/^# //; s/^#//'
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -j|--json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        -c|--csv)
            OUTPUT_FORMAT="csv"
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -d|--delay)
            DELAY="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            show_help
            ;;
        *)
            break
            ;;
    esac
done

USERNAMES=("$@")

if [[ ${#USERNAMES[@]} -eq 0 ]]; then
    echo "Usage: $0 [options] <username1> [username2] ..." >&2
    echo "Use -h for help" >&2
    exit 1
fi

# Open output file if specified
if [[ -n "$OUTPUT_FILE" ]]; then
    exec 3>"$OUTPUT_FILE"
    if [[ "$OUTPUT_FORMAT" == "csv" ]]; then
        # CSV header
        printf '"username","platform","url","status","http_code"\n' >&3
    fi
else
    # Use stdout
    exec 3>&1
fi

echo "OSINT Username Enumeration (Public Profiles Only)" >&2
echo "==================================================" >&2
echo "Platforms: ${#PLATFORMS[@]}" >&2
echo "Delay: ${DELAY}s | Timeout: ${TIMEOUT}s | Format: ${OUTPUT_FORMAT}" >&2
echo >&2

for user in "${USERNAMES[@]}"; do
    case "$OUTPUT_FORMAT" in
        json)
            check_username_json "$user" >&3
            ;;
        csv)
            check_username_csv "$user" >&3
            ;;
        *)
            check_username_text "$user"
            ;;
    esac
done

if [[ -n "$OUTPUT_FILE" ]]; then
    exec 3>&-
    echo "Results written to: $OUTPUT_FILE" >&2
fi

echo >&2
echo "Done. Remember: only PUBLIC profiles are checked." >&2
echo "No private data, no authentication, no scraping behind logins." >&2