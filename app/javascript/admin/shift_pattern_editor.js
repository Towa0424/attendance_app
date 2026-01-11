(() => {
  const initShiftPatternEditor = () => {
    const root = document.querySelector('[data-sp-editor="1"]');
    if (!root) return;

    // Turbo遷移などで二重バインドしない
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

    // 必須要素が足りない場合は安全に終了
    if (!lane || !hoursRow || !hoursEnd || !hover || !groupSelect || !slotsJson || !eraserBtn || !resetBtn) return;

    // ===== Config =====
    const SLOT_W = 18; // 15分スロット幅(px)
    root.style.setProperty("--slot-w", `${SLOT_W}px`);

    // touch でのドラッグ編集安定（※横スクロールと両立したいならここは状況次第）
    lane.style.touchAction = "none";

    // ===== Data load（hidden field から読むのが確実）=====
    let slots = [];
    try {
      slots = JSON.parse(slotsJson.value || "[]");
    } catch (_) {
      slots = [];
    }
    if (!Array.isArray(slots) || slots.length !== 96) slots = Array(96).fill(null);

    // 表示レンジ（slot index）
    let displayRange = { start: 36, end: 80 }; // fallback（09:00〜20:00）
    let activeTimeBlockId = null;

    // drag state
    let isDragging = false;
    let dragStartSlot = null;

    // tool state（消しゴムON/OFF）
    let isEraserActive = false;

    // ===== utils =====
    const clamp = (n, min, max) => Math.max(min, Math.min(max, n));

    const slotToHHMM = (slot) => {
      const total = slot * 15;
      const hh = Math.floor(total / 60) % 24;
      const mm = total % 60;
      return `${String(hh).padStart(2, "0")}:${String(mm).padStart(2, "0")}`;
    };

    const setDisabled = (disabled) => {
      lane.classList.toggle("is-disabled", disabled);
      if (disabled) {
        lane.classList.remove("is-hovering");
        isDragging = false;
        dragStartSlot = null;
      }
    };

    const setSlotsWidth = () => {
      const len = displayRange.end - displayRange.start;
      root.style.setProperty("--slots", String(len));
      lane.style.width = `calc(${len} * ${SLOT_W}px)`;
    };

    // 時間ラベル（endが :00 の時は右端終端ラベルを出さない＝重なり回避）
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
      } else {
        hoursEnd.textContent = slotToHHMM(displayRange.end);
        hoursEnd.style.display = "block";
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

    const showHover = (slot) => {
      lane.classList.add("is-hovering");
      hover.style.left = `calc(${slot - displayRange.start} * ${SLOT_W}px)`;
    };

    const hideHover = () => {
      lane.classList.remove("is-hovering");
    };

    // ===== tool selection（時間ブロック/消しゴム排他） =====
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

    // ★グループ選択後「編集できない」体感を潰す：未選択なら先頭ブロックを自動選択
    const ensureDefaultBlockSelected = () => {
      if (isEraserActive) return;
      if (activeTimeBlockId !== null && Number.isFinite(activeTimeBlockId)) return;

      const first = document.querySelector('.spLegend__item[data-time-block-id]');
      if (first) setActiveTimeBlock(first);
    };

    // 時間ブロック選択
    document.querySelectorAll(".spLegend__item[data-time-block-id]").forEach((btn) => {
      btn.addEventListener("click", () => setActiveTimeBlock(btn));
    });

    // 消しゴム（トグル）
    eraserBtn.addEventListener("click", (e) => {
      e.preventDefault();
      setEraserActive(!isEraserActive);
    });

    // ガントリセット（ガントだけ）
    resetBtn.addEventListener("click", (e) => {
      e.preventDefault();
      slots = Array(96).fill(null);
      renderBlocks();
      updateHidden();
    });

    // ===== drag events =====
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

    const endDrag = () => {
      isDragging = false;
      dragStartSlot = null;
    };

    lane.addEventListener("pointerup", endDrag);
    lane.addEventListener("pointercancel", endDrag);

    // optionの data-start-slot / data-end-slot を採用
    const rangeFromSelectedOption = () => {
      const opt = groupSelect.selectedOptions?.[0];
      if (!opt) return null;

      const start = Number(opt.dataset.startSlot);
      const end = Number(opt.dataset.endSlot);

      if (!Number.isFinite(start) || !Number.isFinite(end) || end <= start) return null;
      return { start, end };
    };

    const applyGroup = () => {
      const gid = groupSelect.value;

      if (!gid) {
        setDisabled(true);
        displayRange = { start: 36, end: 80 };
      } else {
        setDisabled(false);
        displayRange = rangeFromSelectedOption() || { start: 36, end: 80 };

        // ★グループ選択したら「すぐ編集できる」状態にする
        ensureDefaultBlockSelected();
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

  // Turbo対応：遷移しても初期化
  document.addEventListener("turbo:load", initShiftPatternEditor);
  document.addEventListener("turbo:render", initShiftPatternEditor);

  // Turboキャッシュ復元対策：boundフラグを消して再初期化可能にする
  document.addEventListener("turbo:before-cache", () => {
    document.querySelectorAll('[data-sp-editor="1"]').forEach((el) => {
      delete el.dataset.spBound;
    });
  });

  // Turboが無い/無効化の保険
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initShiftPatternEditor);
  } else {
    initShiftPatternEditor();
  }
})();
