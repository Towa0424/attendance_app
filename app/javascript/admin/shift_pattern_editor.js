(() => {
  const initShiftPatternEditor = () => {
    const root = document.querySelector('[data-sp-editor="1"]');
    if (!root) return;

    // Turbo遷移で同一DOMに二重バインドしないようにする
    if (root.dataset.spBound === "1") return;
    root.dataset.spBound = "1";

    const lane = document.getElementById("spLane");
    const hoursRow = document.getElementById("spHoursRow");
    const hoursEnd = document.getElementById("spHoursEnd");
    const hover = document.getElementById("spHover");

    const groupSelect = document.getElementById("spGroupSelect");
    const slotsJson = document.getElementById("spSlotsJson");

    const eraserBtn = document.getElementById("spEraserBtn");
    const resetBtn = document.getElementById("spResetBtn");

    // 必須要素が無いなら安全に抜ける（JSエラーで止まると is-disabled のままになる）
    if (!lane || !hoursRow || !hoursEnd || !hover || !groupSelect || !slotsJson || !eraserBtn || !resetBtn) return;

    const SLOT_W = 18;
    root.style.setProperty("--slot-w", `${SLOT_W}px`);

    let groupRanges = {};
    try {
      groupRanges = JSON.parse(root.dataset.groupRanges || "{}");
    } catch (_) {
      groupRanges = {};
    }

    let slots = [];
    try {
      slots = JSON.parse(root.dataset.initialSlots || "[]");
    } catch (_) {
      slots = [];
    }
    if (!Array.isArray(slots) || slots.length !== 96) slots = Array(96).fill(null);

    let displayRange = { start: 36, end: 80 }; // fallback
    let activeTimeBlockId = null;

    let isDragging = false;
    let dragStartSlot = null;

    // --- Tool state (exclusive) ---
    let isEraserActive = false;

    // iPad / touch でのスクロール干渉を抑える（ドラッグ編集が安定）
    lane.style.touchAction = "none";

    const clamp = (n, min, max) => Math.max(min, Math.min(max, n));

    const slotToHHMM = (slot) => {
      const total = slot * 15;
      const hh = Math.floor(total / 60) % 24;
      const mm = total % 60;
      return `${String(hh).padStart(2, "0")}:${String(mm).padStart(2, "0")}`;
    };

    const setDisabled = (disabled) => {
      lane.classList.toggle("is-disabled", disabled);
    };

    const setSlotsWidth = () => {
      const len = displayRange.end - displayRange.start;
      root.style.setProperty("--slots", String(len));
      lane.style.width = `calc(${len} * ${SLOT_W}px)`;
    };

    // 右端ラベル重なり対策（endが :00 なら endラベルは出さない）
    const renderHours = () => {
      hoursRow.innerHTML = "";

      const startH = Math.floor(displayRange.start / 4);
      const endH = Math.floor(displayRange.end / 4);

      for (let h = startH; h < endH; h++) {
        const cell = document.createElement("div");
        cell.className = "spHourCell";
        cell.textContent = `${String(h).padStart(2, "0")}:00`;
        hoursRow.appendChild(cell);
      }

      const endOnHour = (displayRange.end % 4 === 0);

      if (endOnHour) {
        hoursEnd.textContent = "";
        hoursEnd.style.display = "none";
        hoursRow.style.paddingRight = "0px";
      } else {
        hoursEnd.textContent = slotToHHMM(displayRange.end);
        hoursEnd.style.display = "block";
        hoursRow.style.paddingRight = "56px";
      }
    };

    const updateHidden = () => {
      slotsJson.value = JSON.stringify(slots);
    };

    const clearBlocks = () => {
      lane.querySelectorAll(".spBlock").forEach((n) => n.remove());
    };

    const addBlock = (startSlot, endSlot, timeBlockId) => {
      const btn = document.querySelector(`.spLegend__item[data-time-block-id="${timeBlockId}"]`);
      const color = btn?.dataset?.timeBlockColor || "#22c55e";

      const b = document.createElement("div");
      b.className = "spBlock";
      b.style.setProperty("--start", String(startSlot - displayRange.start));
      b.style.setProperty("--end", String(endSlot - displayRange.start));
      b.style.setProperty("--c", color);
      lane.appendChild(b);
    };

    const renderBlocks = () => {
      clearBlocks();

      let cur = null;
      let curStart = null;

      for (let s = displayRange.start; s < displayRange.end; s++) {
        const v = slots[s] ?? null;
        if (v !== cur) {
          if (cur !== null) addBlock(curStart, s, cur);
          cur = v;
          curStart = s;
        }
      }
      if (cur !== null) addBlock(curStart, displayRange.end, cur);
    };

    const xyToSlot = (clientX) => {
      const rect = lane.getBoundingClientRect();
      const x = clientX - rect.left;
      const idx = Math.floor(x / SLOT_W);
      const within = clamp(idx, 0, (displayRange.end - displayRange.start) - 1);
      return displayRange.start + within;
    };

    const paintRange = (a, b, value) => {
      const from = Math.min(a, b);
      const to = Math.max(a, b);
      for (let s = from; s <= to; s++) slots[s] = value;
    };

    // ====== Tool selection helpers（時間ブロック/消しゴム排他） ======
    const deactivateAllBlocks = () => {
      document.querySelectorAll(".spLegend__item").forEach((b) => b.classList.remove("is-active"));
    };

    const setEraserActive = (on) => {
      isEraserActive = on;
      eraserBtn.classList.toggle("is-on", on);
      eraserBtn.setAttribute("aria-pressed", on ? "true" : "false");

      if (on) {
        activeTimeBlockId = null;
        deactivateAllBlocks();
      }
    };

    const setActiveTimeBlock = (btn) => {
      setEraserActive(false);

      deactivateAllBlocks();
      btn.classList.add("is-active");
      activeTimeBlockId = Number(btn.dataset.timeBlockId);
    };

    // block select
    document.querySelectorAll(".spLegend__item[data-time-block-id]").forEach((btn) => {
      btn.addEventListener("click", () => {
        setActiveTimeBlock(btn);
      });
    });

    // eraser toggle（時間ブロック選択と同じ操作感）
    eraserBtn.addEventListener("click", (e) => {
      e.preventDefault();
      setEraserActive(!isEraserActive);
    });

    // reset (gantt only)
    resetBtn.addEventListener("click", () => {
      slots = Array(96).fill(null);
      renderBlocks();
      updateHidden();
    });

    const showHover = (slot) => {
      lane.classList.add("is-hovering");
      hover.style.left = `calc(${slot - displayRange.start} * ${SLOT_W}px)`;
    };

    const hideHover = () => {
      lane.classList.remove("is-hovering");
    };

    lane.addEventListener("pointermove", (e) => {
      if (lane.classList.contains("is-disabled")) return;

      const s = xyToSlot(e.clientX);
      showHover(s);

      if (!isDragging) return;

      const value = isEraserActive ? null : activeTimeBlockId;
      if (!isEraserActive && (activeTimeBlockId === null || Number.isNaN(activeTimeBlockId))) return;

      paintRange(dragStartSlot, s, value);
      renderBlocks();
      updateHidden();
    });

    lane.addEventListener("pointerleave", hideHover);

    lane.addEventListener("pointerdown", (e) => {
      if (lane.classList.contains("is-disabled")) return;

      const value = isEraserActive ? null : activeTimeBlockId;
      if (!isEraserActive && (activeTimeBlockId === null || Number.isNaN(activeTimeBlockId))) return;

      isDragging = true;
      lane.setPointerCapture?.(e.pointerId);

      dragStartSlot = xyToSlot(e.clientX);
      paintRange(dragStartSlot, dragStartSlot, value);

      renderBlocks();
      updateHidden();
    });

    lane.addEventListener("pointerup", () => {
      isDragging = false;
      dragStartSlot = null;
    });

    lane.addEventListener("pointercancel", () => {
      isDragging = false;
      dragStartSlot = null;
    });

    const rangeForGroup = (gid) => {
      const r = groupRanges[String(gid)];
      return r ? { start: r.start, end: r.end } : { start: 36, end: 80 };
    };

    const applyGroup = () => {
      const gid = groupSelect.value;

      if (!gid) {
        setDisabled(true);
        displayRange = { start: 36, end: 80 };
      } else {
        setDisabled(false);
        displayRange = rangeForGroup(gid);
      }

      setSlotsWidth();
      renderHours();
      renderBlocks();
      updateHidden();
    };

    groupSelect.addEventListener("change", applyGroup);

    // init
    applyGroup();
  };

  // Turbo対応：遷移しても毎回初期化
  document.addEventListener("turbo:load", initShiftPatternEditor);
  document.addEventListener("turbo:render", initShiftPatternEditor);

  // Turboが無い/無効化されてる場合の保険
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initShiftPatternEditor);
  } else {
    initShiftPatternEditor();
  }
})();
