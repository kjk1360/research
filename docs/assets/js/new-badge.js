// Add NEW badge to sidebar nav items and tabs for recent research (within 48h)
(function(){
  const TWO_DAYS = 48 * 60 * 60 * 1000;
  const now = Date.now();

  function addBadge(el) {
    if (el.querySelector(".new-badge")) return;
    const badge = document.createElement("span");
    badge.className = "new-badge";
    badge.textContent = "NEW";
    badge.style.cssText = "background:#f38ba8;color:#1e1e2e;font-size:0.55rem;font-weight:bold;padding:0.1rem 0.35rem;border-radius:3px;margin-left:0.4rem;vertical-align:middle;line-height:1;";
    el.appendChild(badge);
  }

  function isRecent(dateStr) {
    if (!dateStr) return false;
    try {
      const d = new Date(dateStr + "T00:00:00");
      return (now - d.getTime()) < TWO_DAYS;
    } catch(e) { return false; }
  }

  // Sidebar nav links + content links
  document.querySelectorAll(".md-nav__link, .md-content a").forEach(function(el) {
    const href = el.getAttribute("href") || "";
    const text = el.textContent || "";
    const dateMatch = (href + " " + text).match(/(\d{4}-\d{2}-\d{2})/);
    if (dateMatch && isRecent(dateMatch[1])) {
      addBadge(el);
    }
  });

  // Tab labels - check if any child in that section is new
  document.querySelectorAll(".md-tabs__link").forEach(function(tab) {
    const href = tab.getAttribute("href") || "";
    // Find matching sidebar section
    const section = href.replace(/^\/research\//, "").replace(/\/$/, "").split("/")[0];
    if (!section) return;
    const hasNew = document.querySelector('.md-nav__link[href*="' + section + '/"] .new-badge');
    if (hasNew) {
      addBadge(tab);
    }
  });
})();
