// Add NEW badge to sidebar nav items and tabs for recent research
(function(){
  var TWO_DAYS = 48 * 60 * 60 * 1000;

  function isRecent(dateStr) {
    try {
      return (Date.now() - new Date(dateStr + "T12:00:00").getTime()) < TWO_DAYS;
    } catch(e) { return false; }
  }

  function applyBadges() {
    // Remove any existing badges first (prevent duplicates on re-run)
    document.querySelectorAll(".new-badge").forEach(function(b) { b.remove(); });

    // Sidebar nav links only
    document.querySelectorAll(".md-nav__link").forEach(function(el) {
      var href = el.getAttribute("href") || "";
      var m = href.match(/(\d{4}-\d{2}-\d{2})/);
      if (!m) return;
      if (!isRecent(m[1])) return;

      var badge = document.createElement("span");
      badge.className = "new-badge";
      badge.textContent = "NEW";
      badge.style.cssText = "background:#f38ba8;color:#1e1e2e;font-size:0.55rem;font-weight:bold;padding:2px 5px;border-radius:3px;margin-left:6px;vertical-align:middle;line-height:1;display:inline-block;";
      el.appendChild(badge);
    });

    // Also check active page (no href, but has aria-current or --active class)
    document.querySelectorAll(".md-nav__link--active, .md-nav__link[aria-current]").forEach(function(el) {
      if (el.querySelector(".new-badge")) return;
      // Check the page URL itself for a date
      var m = window.location.pathname.match(/(\d{4}-\d{2}-\d{2})/);
      if (m && isRecent(m[1])) {
        var badge = document.createElement("span");
        badge.className = "new-badge";
        badge.textContent = "NEW";
        badge.style.cssText = "background:#f38ba8;color:#1e1e2e;font-size:0.55rem;font-weight:bold;padding:2px 5px;border-radius:3px;margin-left:6px;vertical-align:middle;line-height:1;display:inline-block;";
        el.appendChild(badge);
      }
    });

    // Tab labels - add badge if section contains any new items
    document.querySelectorAll(".md-tabs__link").forEach(function(tab) {
      var href = tab.getAttribute("href") || "";
      var section = href.replace(/^.*\/research\//, "").replace(/\/$/, "").split("/")[0];
      if (!section) return;
      var hasNew = document.querySelector('.md-nav__link[href*="/' + section + '/"] .new-badge') ||
                   document.querySelector('.md-nav__link[href*="' + section + '/"] .new-badge');
      if (hasNew) {
        var badge = document.createElement("span");
        badge.className = "new-badge";
        badge.textContent = "NEW";
        badge.style.cssText = "background:#f38ba8;color:#1e1e2e;font-size:0.55rem;font-weight:bold;padding:2px 5px;border-radius:3px;margin-left:6px;vertical-align:middle;line-height:1;display:inline-block;";
        tab.appendChild(badge);
      }
    });
  }

  // Run after DOM is fully rendered (MkDocs Material does post-load DOM work)
  if (document.readyState === "complete") {
    setTimeout(applyBadges, 150);
  } else {
    window.addEventListener("load", function() {
      setTimeout(applyBadges, 150);
    });
  }
})();
