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
const API = "https://api.github.com/repos/" + REPO + "/issues";

async function loadQuestions() {
  try {
    const [openRes, closedRes] = await Promise.all([
      fetch(API + "?state=open&labels=research-question&per_page=20"),
      fetch(API + "?state=closed&labels=research-question&per_page=20")
    ]);
    const open = await openRes.json();
    const closed = await closedRes.json();

    const pendingEl = document.getElementById("pending-questions");
    const completedEl = document.getElementById("completed-questions");

    if (open.length === 0) {
      pendingEl.innerHTML = '<p style="color:var(--md-default-fg-color--light);">현재 대기 중인 요청이 없습니다.</p>';
    } else {
      pendingEl.innerHTML = '<table><thead><tr><th>요청</th><th>분야</th><th>등록일</th><th>예상</th></tr></thead><tbody>' +
        open.map(i => {
          const date = new Date(i.created_at);
          const cat = extractField(i.body, "분야") || "-";
          const age = Math.floor((Date.now() - date) / 60000);
          const eta = age < 15 ? "다음 주기" : "곧 처리";
          return '<tr><td>' + escHtml(i.title.replace("[Research] ","")) + '</td><td><code>' + cat + '</code></td><td>' + formatDate(date) + '</td><td>' + eta + '</td></tr>';
        }).join("") + '</tbody></table>';
    }

    if (closed.length === 0) {
      completedEl.innerHTML = '<p style="color:var(--md-default-fg-color--light);">아직 완료된 리서치가 없습니다.</p>';
    } else {
      completedEl.innerHTML = '<table><thead><tr><th>요청</th><th>분야</th><th>완료일</th><th>결과</th></tr></thead><tbody>' +
        closed.map(i => {
          const date = new Date(i.closed_at);
          const cat = extractField(i.body, "분야") || "-";
          const link = extractLink(i.body, i.labels);
          return '<tr><td>' + escHtml(i.title.replace("[Research] ","")) + '</td><td><code>' + cat + '</code></td><td>' + formatDate(date) + '</td><td>' + (link ? '<a href="' + link + '">보기</a>' : '완료') + '</td></tr>';
        }).join("") + '</tbody></table>';
    }
  } catch(e) {
    document.getElementById("pending-questions").innerHTML = '<p>Issues 로딩 실패. GitHub API 제한일 수 있습니다.</p>';
    document.getElementById("completed-questions").innerHTML = '';
  }
}

function extractField(body, field) {
  if (!body) return null;
  const m = body.match(new RegExp("### " + field + "\\s*\\n+([^\\n]+)"));
  return m ? m[1].trim() : null;
}

function extractLink(body, labels) {
  if (!body) return null;
  const m = body.match(/\[결과 보기\]\((.*?)\)/);
  return m ? m[1] : null;
}

function formatDate(d) {
  return d.getFullYear() + "-" + String(d.getMonth()+1).padStart(2,"0") + "-" + String(d.getDate()).padStart(2,"0") + " " + String(d.getHours()).padStart(2,"0") + ":" + String(d.getMinutes()).padStart(2,"0");
}

function escHtml(s) {
  const d = document.createElement("div");
  d.textContent = s;
  return d.innerHTML;
}

loadQuestions();
</script>
