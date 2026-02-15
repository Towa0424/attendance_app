(() => {
  const csrfToken = () => {
    const el = document.querySelector('meta[name="csrf-token"]');
    return el ? el.content : "";
  };

  const initLockButton = () => {
    const btn = document.getElementById("js-time-off-lock-btn");
    if (!btn) return;
    if (btn.dataset.bound === "1") return;
    btn.dataset.bound = "1";

    btn.addEventListener("click", async () => {
      const locked = btn.dataset.locked === "true";
      const action = locked ? "ロックを解除" : "ロック";

      if (!confirm(`希望休を${action}しますか？`)) return;

      btn.disabled = true;

      try {
        const res = await fetch(btn.dataset.lockUrl, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken(),
            Accept: "application/json",
          },
          body: JSON.stringify({
            group_id: btn.dataset.groupId,
            month: btn.dataset.month,
          }),
        });

        const data = await res.json().catch(() => ({}));

        if (!res.ok || !data.ok) {
          alert(data.error || "更新に失敗しました");
          return;
        }

        // UI更新
        btn.dataset.locked = data.locked.toString();
        const iconEl = btn.querySelector(".shiftLockBtn__icon");
        const textEl = btn.querySelector(".shiftLockBtn__text");

        if (data.locked) {
          btn.classList.add("shiftLockBtn--locked");
          if (iconEl) iconEl.innerHTML = "&#128274;";
          if (textEl) textEl.textContent = "ロック中";
        } else {
          btn.classList.remove("shiftLockBtn--locked");
          if (iconEl) iconEl.innerHTML = "&#128275;";
          if (textEl) textEl.textContent = "未ロック";
        }
      } catch (_e) {
        alert("通信に失敗しました");
      } finally {
        btn.disabled = false;
      }
    });
  };

  document.addEventListener("turbo:load", initLockButton);
  document.addEventListener("turbo:render", initLockButton);

  document.addEventListener("turbo:before-cache", () => {
    const btn = document.getElementById("js-time-off-lock-btn");
    if (btn) delete btn.dataset.bound;
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initLockButton);
  } else {
    initLockButton();
  }
})();
