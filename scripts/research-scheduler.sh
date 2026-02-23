#!/bin/bash
# Research Scheduler - runs every 15 minutes via launchd
# Checks for new research questions (GitHub Issues) and processes them with Claude CLI

set -euo pipefail

REPO="kjk1360/research"
RESEARCH_DIR="$HOME/research"
DOCS_DIR="$RESEARCH_DIR/docs"
LOG_FILE="$HOME/Library/Logs/research-scheduler/scheduler.log"
LOCK_FILE="/tmp/research-scheduler.lock"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Prevent concurrent runs
if [ -f "$LOCK_FILE" ]; then
  LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
  if kill -0 "$LOCK_PID" 2>/dev/null; then
    log "SKIP: Another instance running (PID $LOCK_PID)"
    exit 0
  fi
  rm -f "$LOCK_FILE"
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# Ensure tools are in PATH
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

log "START: Checking for new research questions..."

# Fetch open issues with research-question label
ISSUES=$(gh issue list --repo "$REPO" --label "research-question" --state open --json number,title,body --limit 10 2>/dev/null || echo "[]")

COUNT=$(echo "$ISSUES" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")

if [ "$COUNT" = "0" ]; then
  log "END: No pending questions. Exiting."
  exit 0
fi

log "FOUND: $COUNT pending question(s). Processing..."

# Process each issue
echo "$ISSUES" | python3 -c "
import sys, json
issues = json.load(sys.stdin)
for i in issues:
    print(f\"{i['number']}|||{i['title']}|||{i['body'] or ''}\")
" | while IFS='|||' read -r ISSUE_NUM ISSUE_TITLE ISSUE_BODY; do
  log "PROCESSING: Issue #$ISSUE_NUM - $ISSUE_TITLE"

  # Extract category from issue body
  CATEGORY=$(echo "$ISSUE_BODY" | python3 -c "
import sys, re
body = sys.stdin.read()
m = re.search(r'### 분야\s*\n+(\S+)', body)
print(m.group(1) if m else 'gaming')
" 2>/dev/null || echo "gaming")

  # Extract email for notification
  NOTIFY_EMAIL=$(echo "$ISSUE_BODY" | python3 -c "
import sys, re
body = sys.stdin.read()
m = re.search(r'### 알림 이메일.*?\n+(\S+@\S+)', body)
print(m.group(1) if m else '')
" 2>/dev/null || echo "")

  # Extract the actual question
  QUESTION=$(echo "$ISSUE_BODY" | python3 -c "
import sys, re
body = sys.stdin.read()
m = re.search(r'### 리서치 질문\s*\n+(.*?)(?=\n### |\Z)', body, re.DOTALL)
print(m.group(1).strip() if m else body.strip())
" 2>/dev/null || echo "$ISSUE_TITLE")

  # Map category to subdirectory
  case "$CATEGORY" in
    gaming)    SUBDIR="gaming/trends" ;;
    marketing) SUBDIR="marketing/strategies" ;;
    creative)  SUBDIR="creative/content" ;;
    finance)   SUBDIR="finance/analysis" ;;
    *)         SUBDIR="_reports" ;;
  esac

  DATE=$(date '+%Y-%m-%d')
  SLUG=$(echo "$QUESTION" | python3 -c "
import sys, re
q = sys.stdin.read().strip()[:60]
q = re.sub(r'[^a-zA-Z0-9가-힣\s-]', '', q)
q = re.sub(r'\s+', '-', q).lower()
print(q or 'research')
")
  FILENAME="${DATE}_${SLUG}.md"
  FILEPATH="$DOCS_DIR/$SUBDIR/$FILENAME"

  mkdir -p "$DOCS_DIR/$SUBDIR"

  # Build the prompt for Claude
  PROMPT="You are a research assistant. Follow these rules strictly:

1. Research the following question thoroughly using web search.
2. Write the result in Korean as a markdown file.
3. Use this YAML frontmatter:
---
date: $DATE
tags: []
sources: []
confidence: medium
status: final
last_updated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
---
4. Structure: 요약 (3줄) → 주요 발견 → 데이터/근거 → 시사점 → 출처
5. Save the file to: $FILEPATH
6. Be thorough, cite sources, and provide actionable insights.

QUESTION: $QUESTION"

  # Run Claude in non-interactive mode
  # unset CLAUDECODE to avoid nested session detection
  if unset CLAUDECODE 2>/dev/null; env -u CLAUDECODE claude -p "$PROMPT" \
    --allowedTools "WebSearch,WebFetch,Read,Write,Edit,Bash,Grep,Glob" \
    --add-dir "$RESEARCH_DIR" \
    --dangerously-skip-permissions \
    --max-turns 15 \
    >> "$LOG_FILE" 2>&1; then

    log "SUCCESS: Research completed for Issue #$ISSUE_NUM"

    # Check if file was created
    if [ -f "$FILEPATH" ]; then
      SITE_PATH="$SUBDIR/$FILENAME"
      SITE_URL="https://kjk1360.github.io/research/${SITE_PATH%.md}/"

      # Update INDEX.md
      cd "$RESEARCH_DIR"

      # Git commit and push
      git add -A
      git commit -m "Research: $ISSUE_TITLE (Issue #$ISSUE_NUM)" >> "$LOG_FILE" 2>&1 || true
      git push >> "$LOG_FILE" 2>&1 || true

      # Comment on issue with result link and close
      gh issue comment "$ISSUE_NUM" --repo "$REPO" \
        --body "리서치가 완료되었습니다.

[결과 보기]($SITE_URL)

파일: \`$SITE_PATH\`" >> "$LOG_FILE" 2>&1

      gh issue close "$ISSUE_NUM" --repo "$REPO" >> "$LOG_FILE" 2>&1

      log "PUBLISHED: $SITE_URL"

      # Send email notification if provided
      if [ -n "$NOTIFY_EMAIL" ]; then
        python3 -c "
import smtplib
from email.mime.text import MIMEText
msg = MIMEText('''리서치가 완료되었습니다.

질문: $QUESTION
결과: $SITE_URL

Research Hub에서 확인하세요.''', 'plain', 'utf-8')
msg['Subject'] = '[Research Hub] $ISSUE_TITLE 완료'
msg['From'] = 'research@localhost'
msg['To'] = '$NOTIFY_EMAIL'
try:
    s = smtplib.SMTP('localhost')
    s.send_message(msg)
    s.quit()
except:
    pass  # Email sending is best-effort
" >> "$LOG_FILE" 2>&1 || true
      fi
    else
      log "WARN: Claude completed but file not found at $FILEPATH"
      # Still try to close issue
      gh issue comment "$ISSUE_NUM" --repo "$REPO" \
        --body "리서치 처리 중 파일 생성에 실패했습니다. 수동 확인이 필요합니다." >> "$LOG_FILE" 2>&1
    fi
  else
    log "ERROR: Claude failed for Issue #$ISSUE_NUM"
    gh issue comment "$ISSUE_NUM" --repo "$REPO" \
      --body "자동 리서치 처리 중 오류가 발생했습니다. 수동 리서치가 필요합니다." >> "$LOG_FILE" 2>&1
  fi

  # Brief pause between issues
  sleep 5
done

log "END: All questions processed."
