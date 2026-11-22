# osintusername-check

A lightweight Bash tool that checks whether a given username exists across ~39 public platforms (GitHub, Reddit, Twitter/X, Instagram, Steam, NPM, PyPI, and more), using only unauthenticated HTTP HEAD requests against public profile URLs.

## What it does

Give it one or more usernames, and it builds the public profile URL for each platform (e.g. `https://github.com/<username>`), sends a `HEAD` request, and classifies the result by HTTP status code:

| Result | HTTP codes | Meaning |
|---|---|---|
| ✓ Found | 200, 301, 302, 307, 308 | Profile likely exists |
| ✗ Not found | 404 | Profile does not exist |
| ⚠ Blocked / rate-limited | 403, 429 | Platform blocked the request — inconclusive |
| ✗ Connection failed | (timeout/DNS/network error) | Could not reach the platform |

It never logs in, never scrapes profile content, and never touches anything behind authentication — it only checks whether a public URL resolves.

## Requirements

- Bash 4+
- `curl`

No other dependencies.

## Installation

```bash
git clone <this-repo-url>
cd osintusername-check
chmod +x osint_username_check.sh
```

## Usage

```bash
./osint_username_check.sh [options] "username1" "username2" ...
```

### Options

| Flag | Description | Default |
|---|---|---|
| `-j`, `--json` | Output JSON instead of human-readable text | off |
| `-c`, `--csv` | Output CSV instead of human-readable text | off |
| `-o`, `--output FILE` | Write results to `FILE` instead of stdout | stdout |
| `-d`, `--delay N` | Seconds to wait between each platform check | `1` |
| `-t`, `--timeout N` | Per-request timeout in seconds | `10` |
| `-h`, `--help` | Show usage help | — |

### Examples

Check a single username, human-readable output:

```bash
./osint_username_check.sh torvalds
```

Check multiple usernames and save as JSON:

```bash
./osint_username_check.sh -j -o results.json torvalds gavin
```

Check as CSV, with a longer delay to be gentler on rate limits:

```bash
./osint_username_check.sh -c -d 3 -o results.csv someuser
```

### Sample text output

```
═══════════════════════════════════════════
  Checking: torvalds
═══════════════════════════════════════════
  ✓ FOUND: GitHub → https://github.com/torvalds
  ✗ Not found: GitLab
  ⚠ Blocked/Rate-limited: Instagram (HTTP 403)
  ...

  Summary: 7 found, 3 errors/blocked
```

## Platforms checked

GitHub, GitLab, Twitter/X, Instagram, Reddit, LinkedIn, Medium, Dev.to, Hacker News, Keybase, Telegram, YouTube, Twitch, TikTok, Pinterest, SoundCloud, Bandcamp, Steam, NPM, PyPI, Crates.io, Docker Hub, Product Hunt, AngelList, CodePen, Replit, GitHub Gist, Pastebin, Bitbucket, SourceForge, Launchpad, GitHub Pages, GitLab Pages, Netlify, Vercel, Heroku, Surge, Firebase, GitBook, Notion, Obsidian Publish.

## Known limitations

- **HEAD requests aren't universally reliable.** Some platforms (notably Instagram, LinkedIn, TikTok) return non-standard codes for bots (`403`, `429`, or odd redirects) regardless of whether the username exists — treat `⚠ Blocked/Rate-limited` results as inconclusive, not negative.
- **Wildcard/subdomain platforms** (GitHub Pages, Netlify, Vercel, Heroku, Bandcamp, etc.) may return `200` for a reserved or parked subdomain even if no one actively uses it — a "found" result there is weaker evidence than on GitHub or Reddit.
- **No retry logic.** A single timeout or transient block is reported as-is; rerun with a higher `-d`/`-t` if you suspect rate limiting.
- **Sequential, not parallel.** Checks run one platform at a time per username, so a full run against all ~39 platforms takes at least `(platforms × delay)` seconds.

## Legal / ethical use

This tool only queries **public** URLs with no authentication and no scraping of page content — it just checks whether a URL resolves. That said, OSINT username enumeration can still be sensitive:

- Use it only for authorized security research, your own accounts, or with the explicit consent of the person you're checking.
- Respect each platform's Terms of Service — automated requests, even simple HEAD checks, may violate some sites' ToS.
- Be mindful of request volume; the default 1-second delay is a courtesy, not a guarantee against rate limiting or IP blocks.

## License

No license has been set yet — all rights reserved by default until one is added.
