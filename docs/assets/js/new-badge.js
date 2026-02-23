// NEW badge - uses build-time generated research-data.js
(function(){
  function applyBadges() {
    var data = window.__RESEARCH_NEW;
    if (!data || !data.titles || !data.titles.length) return;

    var newTitles = data.titles;
    var newSections = data.sections || [];

    function makeBadge() {
      var b = document.createElement("span");
      b.className = "new-badge";
      b.textContent = "NEW";
      b.style.cssText = "background:#f38ba8;color:#1e1e2e;font-size:0.55rem;font-weight:bold;padding:2px 5px;border-radius:3px;margin-left:6px;vertical-align:middle;line-height:1;display:inline-block;";
      return b;
    }

    // Sidebar nav links - match by text content
    document.querySelectorAll(".md-nav__link").forEach(function(el) {
      if (el.querySelector(".new-badge")) return;
      var text = (el.textContent || "").trim();
      for (var i = 0; i < newTitles.length; i++) {
        if (text === newTitles[i]) {
          el.appendChild(makeBadge());
          break;
        }
      }
    });

    // Tab labels - match section names
    document.querySelectorAll(".md-tabs__link").forEach(function(tab) {
      if (tab.querySelector(".new-badge")) return;
      var text = (tab.textContent || "").trim();
      for (var i = 0; i < newSections.length; i++) {
        if (text === newSections[i]) {
          tab.appendChild(makeBadge());
          break;
        }
      }
    });
  }

  if (document.readyState === "complete") {
    setTimeout(applyBadges, 100);
  } else {
    window.addEventListener("load", function() {
      setTimeout(applyBadges, 100);
    });
  }
})();
