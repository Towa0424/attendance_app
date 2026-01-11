(() => {
  const csrfToken = () => {
    const el = document.querySelector('meta[name="csrf-token"]');
    return el ? el.content : "";
  };

  const initShiftMonthEditor = () => {
    document.querySelectorAll('[data-shift-cell-select="1"]').forEach((sel) => {
      if (sel.dataset.bound === "1") return;
      sel.dataset.bound = "1";

      sel.addEventListener("focus", () => {
        sel.dataset.prevValue = sel.value;
      });

      sel.addEventListener("change", async () => {
        const url = sel.dataset.assignUrl;
        const userId = sel.dataset.userId;
        const workDate = sel.dataset.workDate;
        const shiftPatternId = sel.value;

        const prev = sel.dataset.prevValue ?? "";
        sel.disabled = true;
        sel.classList.add("is-loading");

        try {
          const res = await fetch(url, {
            method: "PATCH",
            headers: {
              "Content-Type": "application/json",
              "X-CSRF-Token": csrfToken(),
              "Accept": "application/json",
            },
            body: JSON.stringify({
              user_id: userId,
              work_date: workDate,
              shift_pattern_id: shiftPatternId,
            }),
          });

          const data = await res.json().catch(() => ({}));

          if (!res.ok || !data.ok) {
            const msg = data?.error || "更新に失敗しました";
            alert(msg);
            sel.value = prev;
            return;
          }

          // 成功：現在値を次のprevに
          sel.dataset.prevValue = sel.value;
        } catch (e) {
          alert("通信に失敗しました");
          sel.value = prev;
        } finally {
          sel.disabled = false;
          sel.classList.remove("is-loading");
        }
      });
    });
  };

  document.addEventListener("turbo:load", initShiftMonthEditor);
  document.addEventListener("turbo:render", initShiftMonthEditor);

  document.addEventListener("turbo:before-cache", () => {
    document.querySelectorAll('[data-shift-cell-select="1"]').forEach((el) => {
      delete el.dataset.bound;
    });
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initShiftMonthEditor);
  } else {
    initShiftMonthEditor();
  }
})();
