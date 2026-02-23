// Add NEW badge to research items updated within 6 hours
(function(){
  const SIX_HOURS = 6 * 60 * 60 * 1000;
  const now = Date.now();

  document.querySelectorAll(".md-nav__link, .md-content a").forEach(function(el) {
    const text = el.textContent || "";
    // Match date pattern YYYY-MM-DD in link text or href
    const href = el.getAttribute("href") || "";
    const dateMatch = (href + " " + text).match(/(\d{4}-\d{2}-\d{2})/);
    if (!dateMatch) return;

    const fileDate = new Date(dateMatch[1] + "T00:00:00");
    if (now - fileDate.getTime() < SIX_HOURS * 4) { // Within 24h for date-based (generous for daily files)
      const badge = document.createElement("span");
      badge.textContent = "NEW";
      badge.style.cssText = "background:#f38ba8;color:#1e1e2e;font-size:0.6rem;font-weight:bold;padding:0.1rem 0.4rem;border-radius:4px;margin-left:0.5rem;vertical-align:middle;";
      el.appendChild(badge);
    }
  });

  // Also check via git commit metadata if available
  const meta = document.querySelector('meta[name="last-updated"]');
  if (meta) {
    const updated = new Date(meta.content);
    if (now - updated.getTime() < SIX_HOURS) {
      const title = document.querySelector("h1");
      if (title) {
        const badge = document.createElement("span");
        badge.textContent = "NEW";
        badge.style.cssText = "background:#f38ba8;color:#1e1e2e;font-size:0.7rem;font-weight:bold;padding:0.15rem 0.5rem;border-radius:4px;margin-left:0.75rem;vertical-align:middle;";
        title.appendChild(badge);
      }
    }
  }
})();
