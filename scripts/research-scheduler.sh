#!/bin/bash
# Research Scheduler - runs every 15 minutes via launchd
set -euo pipefail

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
export HOME="/Users/lulaeng"

REPO="kjk1360/research"
RESEARCH_DIR="$HOME/research"
LOG_DIR="$HOME/Library/Logs/research-scheduler"
LOG_FILE="$LOG_DIR/scheduler.log"
LOCK_FILE="/tmp/research-scheduler.lock"

mkdir -p "$LOG_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

# Prevent concurrent runs
if [ -f "$LOCK_FILE" ]; then
  LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
  if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
    log "SKIP: Another instance running (PID $LOCK_PID)"
    exit 0
  fi
  rm -f "$LOCK_FILE"
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

log "START: Checking for new research questions..."

# Use Python to handle the full flow of fetching and dispatching
python3 << 'PYTHON_SCRIPT'
import subprocess, json, re, os, sys
from datetime import datetime, timezone

REPO = "kjk1360/research"
RESEARCH_DIR = os.path.expanduser("~/research")
DOCS_DIR = os.path.join(RESEARCH_DIR, "docs")
LOG_FILE = os.path.expanduser("~/Library/Logs/research-scheduler/scheduler.log")

def log(msg):
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{ts}] {msg}\n")

# Fetch open issues
result = subprocess.run(
    ["gh", "issue", "list", "--repo", REPO, "--label", "research-question",
     "--state", "open", "--json", "number,title,body", "--limit", "10"],
    capture_output=True, text=True
)

if result.returncode != 0:
    log(f"ERROR: gh issue list failed: {result.stderr}")
    sys.exit(1)

issues = json.loads(result.stdout)
if not issues:
    log("END: No pending questions. Exiting.")
    sys.exit(0)

log(f"FOUND: {len(issues)} pending question(s). Processing...")

for issue in issues:
    num = issue["number"]
    title = issue["title"]
    body = issue.get("body", "") or ""

    log(f"PROCESSING: Issue #{num} - {title}")

    # Extract fields from issue body
    q_match = re.search(r"### 리서치 질문\s*\n+(.*?)(?=\n### |\Z)", body, re.DOTALL)
    question = q_match.group(1).strip() if q_match else title.replace("[Research] ", "")

    cat_match = re.search(r"### 분야\s*\n+(\S+)", body)
    category = cat_match.group(1).strip() if cat_match else "gaming"

    email_match = re.search(r"### 알림 이메일.*?\n+(\S+@\S+)", body)
    notify_email = email_match.group(1) if email_match else ""

    # Map category to subdir
    cat_map = {"gaming": "gaming/trends", "marketing": "marketing/strategies",
               "creative": "creative/content", "finance": "finance/analysis"}
    subdir = cat_map.get(category, "_reports")

    date = datetime.now().strftime("%Y-%m-%d")
    now_utc = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Create slug from title (not question body) - keep short
    slug_src = title.replace("[Research] ", "").strip()[:40]
    slug = re.sub(r"[^a-zA-Z0-9가-힣\s-]", "", slug_src)
    slug = re.sub(r"\s+", "-", slug).lower() or "research"
    filename = f"{date}_{slug}.md"
    filepath = os.path.join(DOCS_DIR, subdir, filename)

    os.makedirs(os.path.join(DOCS_DIR, subdir), exist_ok=True)

    # Write prompt to temp file
    prompt_file = f"/tmp/research-prompt-{num}.txt"
    with open(prompt_file, "w") as pf:
        pf.write(f"""You are a research assistant for a Korean user. Follow these rules strictly:

1. Research the following question thoroughly using WebSearch and WebFetch tools.
2. Write the result in Korean as a markdown file using the Write tool.
3. The file MUST be saved to exactly this path: {filepath}
4. Start the file with this YAML frontmatter:
---
date: {date}
tags: []
sources: []
confidence: medium
status: final
last_updated: {now_utc}
---
5. Structure the content as: # Title → ## 요약 (3줄) → ## 주요 발견 → ## 데이터/근거 → ## 시사점 → ## 출처
6. Be thorough, cite sources with URLs, and provide actionable insights.
7. Fill in the tags and sources in the frontmatter based on your research.

RESEARCH QUESTION: {question}""")

    # Run Claude CLI with prompt from stdin
    env = os.environ.copy()
    env.pop("CLAUDECODE", None)

    log(f"CLAUDE CMD: claude -p <prompt_file> for issue #{num}, filepath={filepath}")

    with open(prompt_file, "r") as pf:
        claude_result = subprocess.run(
            ["claude", "-p", "-",
             "--allowedTools", "WebSearch,WebFetch,Read,Write,Edit,Bash,Grep,Glob",
             "--add-dir", RESEARCH_DIR,
             "--dangerously-skip-permissions",
             "--max-turns", "15"],
            stdin=pf, capture_output=True, text=True, env=env, timeout=300
        )

    log(f"CLAUDE EXIT: {claude_result.returncode}")
    os.remove(prompt_file)

    # Check if file was created (also check for slight naming variations)
    file_found = os.path.exists(filepath)
    if not file_found:
        # Search for any new .md file in the subdir
        target_dir = os.path.join(DOCS_DIR, subdir)
        for f in os.listdir(target_dir):
            if f.startswith(date) and f.endswith(".md"):
                filepath = os.path.join(target_dir, f)
                filename = f
                file_found = True
                log(f"FOUND ALT FILE: {filepath}")
                break

    if file_found:
        log(f"SUCCESS: Research completed for Issue #{num}")

        site_url = f"https://kjk1360.github.io/research/{subdir}/{filename.replace('.md', '')}/"

        # Git commit and push
        os.chdir(RESEARCH_DIR)
        subprocess.run(["git", "add", "-A"], capture_output=True)
        subprocess.run(["git", "commit", "-m", f"Research: {title} (Issue #{num})"], capture_output=True)
        subprocess.run(["git", "push"], capture_output=True)

        # Comment and close issue
        comment = f"리서치가 완료되었습니다.\n\n[결과 보기]({site_url})\n\n파일: `{subdir}/{filename}`"
        subprocess.run(["gh", "issue", "comment", str(num), "--repo", REPO, "--body", comment], capture_output=True)
        subprocess.run(["gh", "issue", "close", str(num), "--repo", REPO], capture_output=True)

        log(f"PUBLISHED: {site_url}")
    else:
        log(f"ERROR: Claude failed for Issue #{num}")
        log(f"STDOUT: {claude_result.stdout[-500:] if claude_result.stdout else 'empty'}")
        log(f"STDERR: {claude_result.stderr[-500:] if claude_result.stderr else 'empty'}")
        err_comment = "자동 리서치 처리 중 오류가 발생했습니다. 수동 리서치가 필요합니다."
        subprocess.run(["gh", "issue", "comment", str(num), "--repo", REPO, "--body", err_comment], capture_output=True)

log("END: All questions processed.")
PYTHON_SCRIPT
