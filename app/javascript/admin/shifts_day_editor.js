(() => {
  const csrfToken = () => {
    const el = document.querySelector('meta[name="csrf-token"]');
    return el ? el.content : "";
  };

  const initShiftDayEditor = () => {
    const root = document.querySelector('[data-shift-day-editor="1"]');
    if (!root) return;

    if (root.dataset.bound === "1") return;
    root.dataset.bound = "1";

    const assignUrl = root.dataset.assignUrl;
    const updateUrl = root.dataset.updateUrl;
    const rangeStart = Number(root.dataset.rangeStart);
    const rangeEnd = Number(root.dataset.rangeEnd);
    const slotWidth = 18;

    const legendButtons = document.querySelectorAll('[data-time-block-id]');
    const eraserBtn = document.querySelector('[data-shift-day-eraser="1"]');

    const colorMap = new Map();
    legendButtons.forEach((btn) => {
      colorMap.set(Number(btn.dataset.timeBlockId), btn.dataset.timeBlockColor || "#22c55e");
    });

    let activeTimeBlockId = null;
    let isEraserActive = false;
    let isDragging = false;
    let dragStartSlot = null;
    let activeLane = null;

    const laneState = new Map();

    const parseSlots = (lane) => {
      try {
        const slots = JSON.parse(lane.dataset.slots || "[]");
        if (Array.isArray(slots) && slots.length === 96) return slots;
      } catch (_) {
        return Array(96).fill(null);
      }
      return Array(96).fill(null);
    };

    const blocksFromSlots = (slots) => {
      const blocks = [];
      let curId = null;
      let curStart = null;

      for (let i = rangeStart; i < rangeEnd; i += 1) {
        const id = slots[i] ?? null;
        if (id !== curId) {
          if (curId !== null) blocks.push({ start: curStart, end: i, timeBlockId: curId });
          curId = id;
          curStart = i;
        }
      }

      if (curId !== null) blocks.push({ start: curStart, end: rangeEnd, timeBlockId: curId });
      return blocks;
    };

    const renderLane = (lane) => {
      const state = laneState.get(lane);
      if (!state) return;

      lane.querySelectorAll(".shiftDayBlock").forEach((n) => n.remove());

      const blocks = blocksFromSlots(state.slots);
      blocks.forEach((b) => {
        const block = document.createElement("div");
        block.className = "shiftDayBlock";
        block.style.setProperty("--start", String(b.start - rangeStart));
        block.style.setProperty("--end", String(b.end - rangeStart));
        block.style.setProperty("--c", colorMap.get(Number(b.timeBlockId)) || "#22c55e");
        lane.appendChild(block);
      });

      const hint = lane.querySelector(".shiftDayLane__hint");
      if (hint) {
        hint.style.display = blocks.length > 0 ? "none" : "flex";
      }
    };

    const setLaneSlots = (lane, slots) => {
      lane.dataset.slots = JSON.stringify(slots);
      laneState.set(lane, { slots });
      renderLane(lane);
    };

    const setLaneDisabled = (lane, disabled) => {
      lane.classList.toggle("is-disabled", disabled);
    };

    const clamp = (n, min, max) => Math.max(min, Math.min(max, n));

    const xyToSlot = (lane, clientX) => {
      const rect = lane.getBoundingClientRect();
      const x = clientX - rect.left;
      const idx = Math.floor(x / slotWidth);
      const within = clamp(idx, 0, (rangeEnd - rangeStart) - 1);
      return rangeStart + within;
    };

    const paintRange = (slots, a, b, value) => {
      const from = Math.min(a, b);
      const to = Math.max(a, b);
      for (let s = from; s <= to; s += 1) slots[s] = value;
    };

    const setEraserActive = (on) => {
      isEraserActive = on;
      if (eraserBtn) {
        eraserBtn.classList.toggle("is-on", on);
        eraserBtn.setAttribute("aria-pressed", on ? "true" : "false");
      }

      if (on) {
        activeTimeBlockId = null;
        legendButtons.forEach((b) => b.classList.remove("is-active"));
      }
    };

    legendButtons.forEach((btn) => {
      btn.addEventListener("click", () => {
        setEraserActive(false);
        legendButtons.forEach((b) => b.classList.remove("is-active"));
        btn.classList.add("is-active");
        activeTimeBlockId = Number(btn.dataset.timeBlockId);
      });
    });

    if (eraserBtn) {
      eraserBtn.addEventListener("click", () => {
        setEraserActive(!isEraserActive);
      });
    }

    root.querySelectorAll('[data-shift-day-lane="1"]').forEach((lane) => {
      laneState.set(lane, { slots: parseSlots(lane) });
    });

    const saveLane = async (lane) => {
      const state = laneState.get(lane);
      if (!state) return;

      const userId = lane.dataset.userId;
      const workDate = lane.dataset.workDate;

      lane.dataset.saving = "1";

      try {
        const submitSlots = state.slots.map((val) => (val == null ? "" : val));
        const res = await fetch(updateUrl, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken(),
            "Accept": "application/json",
          },
          body: JSON.stringify({
            user_id: userId,
            work_date: workDate,
            slots: submitSlots,
            range_start: rangeStart,
            range_end: rangeEnd,            
          }),
        });

        const data = await res.json().catch(() => ({}));

        if (!res.ok || !data.ok) {
          const msg = data?.error || "更新に失敗しました";
          alert(msg);
        } else {
          lane.dataset.slots = JSON.stringify(state.slots);
        }
      } catch (e) {
        alert("通信に失敗しました");
      } finally {
        delete lane.dataset.saving;
      }
    };

    root.querySelectorAll('[data-shift-day-lane="1"]').forEach((lane) => {
      lane.addEventListener("pointerdown", (e) => {
        if (lane.classList.contains("is-disabled")) return;

        if (!isEraserActive && (activeTimeBlockId === null || Number.isNaN(activeTimeBlockId))) return;

        isDragging = true;
        activeLane = lane;
        dragStartSlot = xyToSlot(lane, e.clientX);

        const state = laneState.get(lane);
        if (!state) return;

        const value = isEraserActive ? null : activeTimeBlockId;
        paintRange(state.slots, dragStartSlot, dragStartSlot, value);
        renderLane(lane);

        lane.setPointerCapture?.(e.pointerId);
      });

      lane.addEventListener("pointermove", (e) => {
        if (!isDragging || activeLane !== lane) return;
        const state = laneState.get(lane);
        if (!state) return;

        const value = isEraserActive ? null : activeTimeBlockId;
        if (!isEraserActive && (activeTimeBlockId === null || Number.isNaN(activeTimeBlockId))) return;

        const currentSlot = xyToSlot(lane, e.clientX);
        paintRange(state.slots, dragStartSlot, currentSlot, value);
        renderLane(lane);
      });

      const finishDrag = () => {
        if (!isDragging || activeLane !== lane) return;
        isDragging = false;
        dragStartSlot = null;
        activeLane = null;
        saveLane(lane);
      };

      lane.addEventListener("pointerup", finishDrag);
      lane.addEventListener("pointercancel", finishDrag);
    });

    root.querySelectorAll('[data-shift-day-pattern-select="1"]').forEach((sel) => {
      if (sel.dataset.bound === "1") return;
      sel.dataset.bound = "1";

      sel.addEventListener("focus", () => {
        sel.dataset.prevValue = sel.value;
      });

      sel.addEventListener("change", async () => {
        const userId = sel.dataset.userId;
        const workDate = sel.dataset.workDate;
        const shiftPatternId = sel.value;
        const prev = sel.dataset.prevValue ?? "";

        const lane = root.querySelector(
          `[data-shift-day-lane="1"][data-user-id="${userId}"]`
        );

        sel.disabled = true;
        sel.classList.add("is-loading");

        try {
          const res = await fetch(assignUrl, {
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

          const slots = Array.isArray(data.slots) ? data.slots : Array(96).fill(null);
          if (lane) {
            setLaneSlots(lane, slots);
            setLaneDisabled(lane, shiftPatternId === "");
          }

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

  document.addEventListener("turbo:load", initShiftDayEditor);
  document.addEventListener("turbo:render", initShiftDayEditor);

  document.addEventListener("turbo:before-cache", () => {
    document.querySelectorAll('[data-shift-day-editor="1"]').forEach((el) => {
      delete el.dataset.bound;
    });

    document.querySelectorAll('[data-shift-day-pattern-select="1"]').forEach((el) => {
      delete el.dataset.bound;
    });
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initShiftDayEditor);
  } else {
    initShiftDayEditor();
  }
})();
