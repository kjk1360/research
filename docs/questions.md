# Research Queue

리서치 요청 현황입니다. 15분 간격으로 자동 처리됩니다.

<a href="https://github.com/kjk1360/research/issues/new?template=research-question.yml" target="_blank" class="md-button md-button--primary" style="margin-bottom:1.5rem;display:inline-block;">
  + 새 리서치 요청
</a>

## 대기 중 (Pending)

<div id="pending-questions">로딩 중...</div>

## 완료 (Completed)

<div id="completed-questions">로딩 중...</div>

<script>
const REPO = "kjk1360/research";
const API = "https://api.github.com/repos/" + REPO;

async function loadQuestions() {
  try {
    const [openRes, closedRes] = await Promise.all([
      fetch(API + "/issues?state=open&labels=research-question&per_page=20"),
      fetch(API + "/issues?state=closed&labels=research-question&per_page=20&sort=updated&direction=desc")
    ]);
    const open = await openRes.json();
    const closed = await closedRes.json();

    // Pending
    const pendingEl = document.getElementById("pending-questions");
    if (!open.length) {
      pendingEl.innerHTML = '<p style="color:var(--md-default-fg-color--light);">현재 대기 중인 요청이 없습니다.</p>';
    } else {
      pendingEl.innerHTML = '<table><thead><tr><th>요청</th><th>분야</th><th>등록일</th><th>상태</th></tr></thead><tbody>' +
        open.map(i => {
          const date = new Date(i.created_at);
          const cat = extractField(i.body, "분야") || "-";
          const age = Math.floor((Date.now() - date) / 60000);
          const status = age < 15 ? "⏳ 다음 주기" : "🔄 처리 중";
          return '<tr><td>' + esc(i.title.replace("[Research] ","")) + '</td><td><code>' + cat + '</code></td><td>' + fmt(date) + '</td><td>' + status + '</td></tr>';
        }).join("") + '</tbody></table>';
    }

    // Completed - fetch comments to get result links
    const completedEl = document.getElementById("completed-questions");
    if (!closed.length) {
      completedEl.innerHTML = '<p style="color:var(--md-default-fg-color--light);">아직 완료된 리서치가 없습니다.</p>';
      return;
    }

    // Fetch comments for all closed issues in parallel
    const commentPromises = closed.map(i =>
      fetch(API + "/issues/" + i.number + "/comments?per_page=5")
        .then(r => r.json())
        .catch(() => [])
    );
    const allComments = await Promise.all(commentPromises);

    completedEl.innerHTML = '<table><thead><tr><th>요청</th><th>분야</th><th>완료일</th><th>결과</th></tr></thead><tbody>' +
      closed.map((i, idx) => {
        const date = new Date(i.closed_at);
        const cat = extractField(i.body, "분야") || "-";
        const link = findResultLink(allComments[idx]);
        const resultCell = link
          ? '<a href="' + link + '" style="font-weight:bold;">📄 보기</a>'
          : '<span style="color:var(--md-default-fg-color--light);">완료</span>';
        return '<tr><td>' + esc(i.title.replace("[Research] ","")) + '</td><td><code>' + cat + '</code></td><td>' + fmt(date) + '</td><td>' + resultCell + '</td></tr>';
      }).join("") + '</tbody></table>';

  } catch(e) {
    document.getElementById("pending-questions").innerHTML = '<p>로딩 실패. 새로고침 해주세요.</p>';
    document.getElementById("completed-questions").innerHTML = '';
  }
}

function findResultLink(comments) {
  if (!comments || !comments.length) return null;
  for (const c of comments) {
    const m = (c.body || "").match(/\[결과 보기\]\((.*?)\)/);
    if (m) return m[1];
  }
  return null;
}

function extractField(body, field) {
  if (!body) return null;
  const m = body.match(new RegExp("### " + field + "\\s*\\n+([^\\n]+)"));
  return m ? m[1].trim() : null;
}

function fmt(d) {
  return d.getFullYear() + "-" + String(d.getMonth()+1).padStart(2,"0") + "-" + String(d.getDate()).padStart(2,"0") + " " + String(d.getHours()).padStart(2,"0") + ":" + String(d.getMinutes()).padStart(2,"0");
}

function esc(s) {
  const d = document.createElement("div");
  d.textContent = s;
  return d.innerHTML;
}

loadQuestions();
</script>
