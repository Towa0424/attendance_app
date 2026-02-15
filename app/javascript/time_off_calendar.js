(() => {
  const csrfToken = () => {
    const el = document.querySelector('meta[name="csrf-token"]');
    return el ? el.content : "";
  };

  const initTimeOffCalendar = () => {
    const cal = document.getElementById("js-time-off-calendar");
    if (!cal) return;
    if (cal.dataset.bound === "1") return;
    cal.dataset.bound = "1";

    const toggleUrl = cal.dataset.toggleUrl;
    const locked = cal.dataset.locked === "true";

    if (locked) return;

    const cells = cal.querySelectorAll(".toCal__cell[data-date]");

    cells.forEach((cell) => {
      cell.style.cursor = "pointer";

      cell.addEventListener("click", () => {
        showTypeSelector(cell, toggleUrl);
      });
    });
  };

  const showTypeSelector = (cell, toggleUrl) => {
    // 既存のポップアップを削除
    const existing = document.querySelector(".toPopup");
    if (existing) existing.remove();

    const currentType = cell.dataset.requestType;
    const date = cell.dataset.date;

    const popup = document.createElement("div");
    popup.className = "toPopup";

    const options = [
      { type: "preferred", label: "希望", className: "toPopup__btn--preferred" },
      { type: "fixed", label: "固定休", className: "toPopup__btn--fixed" },
    ];

    if (currentType) {
      options.push({ type: "remove", label: "取り消し", className: "toPopup__btn--remove" });
    }

    options.forEach((opt) => {
      const btn = document.createElement("button");
      btn.className = `toPopup__btn ${opt.className}`;
      btn.textContent = opt.label;

      if (opt.type === currentType) {
        btn.classList.add("is-current");
      }

      btn.addEventListener("click", async (e) => {
        e.stopPropagation();
        popup.remove();

        await sendToggle(cell, toggleUrl, date, opt.type);
      });

      popup.appendChild(btn);
    });

    // ポップアップ外クリックで閉じる
    const closeHandler = (e) => {
      if (!popup.contains(e.target) && e.target !== cell) {
        popup.remove();
        document.removeEventListener("click", closeHandler);
      }
    };
    setTimeout(() => document.addEventListener("click", closeHandler), 0);

    cell.style.position = "relative";
    cell.appendChild(popup);
  };

  const sendToggle = async (cell, url, date, requestType) => {
    cell.classList.add("is-loading");

    try {
      const res = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken(),
          Accept: "application/json",
        },
        body: JSON.stringify({
          target_date: date,
          request_type: requestType,
        }),
      });

      const data = await res.json().catch(() => ({}));

      if (!res.ok || !data.ok) {
        alert(data.error || "更新に失敗しました");
        return;
      }

      // UIを更新
      updateCell(cell, data.removed ? null : requestType);
    } catch (_e) {
      alert("通信に失敗しました");
    } finally {
      cell.classList.remove("is-loading");
    }
  };

  const updateCell = (cell, requestType) => {
    // クラスをリセット
    cell.classList.remove("is-preferred", "is-fixed");
    cell.dataset.requestType = requestType || "";

    const markEl = cell.querySelector(".toCal__mark");
    if (!markEl) return;

    if (requestType === "preferred") {
      cell.classList.add("is-preferred");
      markEl.innerHTML = '<span class="toCal__badge toCal__badge--preferred">希望</span>';
    } else if (requestType === "fixed") {
      cell.classList.add("is-fixed");
      markEl.innerHTML = '<span class="toCal__badge toCal__badge--fixed">固定休</span>';
    } else {
      markEl.innerHTML = "";
    }
  };

  document.addEventListener("turbo:load", initTimeOffCalendar);
  document.addEventListener("turbo:render", initTimeOffCalendar);

  document.addEventListener("turbo:before-cache", () => {
    const cal = document.getElementById("js-time-off-calendar");
    if (cal) delete cal.dataset.bound;
    const popup = document.querySelector(".toPopup");
    if (popup) popup.remove();
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initTimeOffCalendar);
  } else {
    initTimeOffCalendar();
  }
})();
