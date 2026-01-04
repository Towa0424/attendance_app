function initColorPick() {
  document.querySelectorAll("[data-color-pick]").forEach((wrap) => {
    const hidden = wrap.closest(".form__row")?.querySelector(".js-colorValue");
    const chip = wrap.closest(".form__row")?.querySelector(".js-colorChip");
    const text = wrap.closest(".form__row")?.querySelector(".js-colorText");
    const picker = wrap.closest(".form__row")?.querySelector(".js-colorPicker");

    if (!hidden) return;

    const setColor = (hex) => {
      if (!hex) return;
      hidden.value = hex;
      if (chip) chip.style.setProperty("--c", hex);
      if (text) text.textContent = hex;

      wrap.querySelectorAll(".js-swatch").forEach((b) => {
        b.classList.toggle("is-selected", b.dataset.color?.toLowerCase() === hex.toLowerCase());
      });

      if (picker) picker.value = hex;
    };

    // 初期選択（未入力ならデフォルト）
    setColor(hidden.value || picker?.value || "#3b82f6");

    // パレットクリック
    wrap.addEventListener("click", (e) => {
      const btn = e.target.closest(".js-swatch");
      if (!btn) return;
      setColor(btn.dataset.color);
    });

    // その他の色（カラーピッカー）
    if (picker) {
      picker.addEventListener("input", () => setColor(picker.value));
    }
  });
}

document.addEventListener("turbo:load", initColorPick);
document.addEventListener("DOMContentLoaded", initColorPick);
