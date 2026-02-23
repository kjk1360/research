(function(){
  const HASH = "d83036ffb5b49a153bc391fd12b4a10df06bbb200f39fed97c331b03b6833ce7";
  const KEY = "research_auth";

  async function sha256(msg) {
    const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(msg));
    return Array.from(new Uint8Array(buf)).map(b=>b.toString(16).padStart(2,"0")).join("");
  }

  const stored = sessionStorage.getItem(KEY);
  if (stored === HASH) return;

  // Hide all content
  document.documentElement.style.overflow = "hidden";

  const gate = document.createElement("div");
  gate.id = "password-gate";
  gate.innerHTML = `
    <div style="position:fixed;top:0;left:0;width:100%;height:100%;background:#1e1e2e;z-index:99999;display:flex;align-items:center;justify-content:center;">
      <div style="text-align:center;padding:2rem;color:#cdd6f4;">
        <div style="font-size:3rem;margin-bottom:1rem;">&#128274;</div>
        <h2 style="margin-bottom:0.5rem;color:#cdd6f4;">Research Hub</h2>
        <p style="margin-bottom:1.5rem;color:#a6adc8;">Access password required</p>
        <input id="pwd-input" type="password" placeholder="Password"
          style="padding:0.75rem 1rem;font-size:1rem;border:2px solid #6c7086;border-radius:8px;outline:none;width:280px;background:#313244;color:#cdd6f4;text-align:center;"
          autofocus>
        <br>
        <button id="pwd-btn"
          style="margin-top:1rem;padding:0.75rem 2rem;font-size:1rem;background:#89b4fa;color:#1e1e2e;border:none;border-radius:8px;cursor:pointer;font-weight:bold;">
          Enter
        </button>
        <p id="pwd-error" style="color:#f38ba8;margin-top:0.75rem;display:none;">Wrong password</p>
      </div>
    </div>
  `;
  document.body.appendChild(gate);

  async function checkPwd() {
    const input = document.getElementById("pwd-input").value;
    if ((await sha256(input)) === HASH) {
      sessionStorage.setItem(KEY, HASH);
      gate.remove();
      document.documentElement.style.overflow = "";
    } else {
      document.getElementById("pwd-error").style.display = "block";
      document.getElementById("pwd-input").value = "";
      document.getElementById("pwd-input").focus();
    }
  }

  document.getElementById("pwd-btn").addEventListener("click", checkPwd);
  document.getElementById("pwd-input").addEventListener("keydown", function(e) {
    if (e.key === "Enter") checkPwd();
  });
})();
