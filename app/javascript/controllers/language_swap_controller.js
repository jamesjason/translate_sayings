import { Controller } from "@hotwired/stimulus";
import LanguagePreference from "services/language_preference"

export default class extends Controller {
  static targets = [
    "sourceMenu",
    "targetMenu",
    "sourceLabel",
    "targetLabel",
    "sourceInput",
    "targetInput"
  ];

  connect() {
    this._outsideClick = this.handleClickOutside.bind(this);
    document.addEventListener("click", this._outsideClick);

    const saved = LanguagePreference.read();
    if (saved) {
      const code = saved;
      const option = this.targetMenuTarget.querySelector(`[data-code="${code}"]`);
      if (option) {
        const name = option.dataset.name;

        this.targetInputTarget.value = code;

        const span = this.targetLabelTarget.querySelector("span");
        if (span) span.textContent = name;

        this.updateMenuSelection(this.targetMenuTarget, code);
      }
    }
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick);
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.closeMenus();
    }
  }

  closeMenus() {
    if (this.hasSourceMenuTarget) this.sourceMenuTarget.classList.add("hidden");
    if (this.hasTargetMenuTarget) this.targetMenuTarget.classList.add("hidden");
  }

  toggleSourceMenu(event) {
    event.stopPropagation();
    if (!this.hasSourceMenuTarget) return;

    const shouldShow = this.sourceMenuTarget.classList.contains("hidden");
    this.closeMenus();

    if (shouldShow) {
      this.updateMenuSelection(this.sourceMenuTarget, this.sourceInputTarget.value);
      this.sourceMenuTarget.classList.remove("hidden");
    }
  }

  toggleTargetMenu(event) {
    event.stopPropagation();
    if (!this.hasTargetMenuTarget) return;

    const shouldShow = this.targetMenuTarget.classList.contains("hidden");
    this.closeMenus();

    if (shouldShow) {
      this.updateMenuSelection(this.targetMenuTarget, this.targetInputTarget.value);
      this.targetMenuTarget.classList.remove("hidden");
    }
  }

  chooseSource(event) {
    this.applySelection({
      event,
      input: this.sourceInputTarget,
      label: this.sourceLabelTarget,
      menu: this.sourceMenuTarget,
      dispatchName: "ts:source-language-changed"
    });
  }

  chooseTarget(event) {
    this.applySelection({
      event,
      input: this.targetInputTarget,
      label: this.targetLabelTarget,
      menu: this.targetMenuTarget,
      dispatchName: "ts:target-language-changed"
    });

    const code = event.currentTarget.dataset.code;
    LanguagePreference.write(code);
  }

  applySelection({ event, input, label, menu, dispatchName }) {
    const btn = event.currentTarget;
    const code = btn.dataset.code;
    const name = btn.dataset.name;

    input.value = code;

    const labelSpan = label.querySelector("span");
    if (labelSpan) labelSpan.textContent = name;

    this.updateMenuSelection(menu, code);
    this.closeMenus();

    window.dispatchEvent(new CustomEvent(dispatchName, { detail: { code, name } }));
  }

  swap(event) {
    event.stopPropagation();

    const sourceCode = this.sourceInputTarget.value;
    const targetCode = this.targetInputTarget.value;

    const sourceName = this.sourceLabelTarget.querySelector("span")?.textContent;
    const targetName = this.targetLabelTarget.querySelector("span")?.textContent;

    this.sourceInputTarget.value = targetCode;
    this.targetInputTarget.value = sourceCode;

    if (sourceName && targetName) {
      this.sourceLabelTarget.querySelector("span").textContent = targetName;
      this.targetLabelTarget.querySelector("span").textContent = sourceName;
    }

    window.dispatchEvent(
      new CustomEvent("ts:source-language-changed", {
        detail: { code: targetCode, name: targetName }
      })
    );

    window.dispatchEvent(
      new CustomEvent("ts:target-language-changed", {
        detail: { code: sourceCode, name: sourceName }
      })
    );

    LanguagePreference.write(sourceCode);

    this.closeMenus();
  }

  updateMenuSelection(menuEl, selectedCode) {
    menuEl.querySelectorAll("button[data-code]").forEach((btn) => {
      const isActive = btn.dataset.code === selectedCode;
      btn.classList.toggle("bg-slate-50", isActive);

      const check = btn.querySelector('[data-role="check"]');
      if (check) check.classList.toggle("hidden", !isActive);
    });
  }
}
