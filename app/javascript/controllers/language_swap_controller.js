import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "sourceMenu",
    "targetMenu",
    "sourceLabel",
    "targetLabel",
    "sourceInput",
    "targetInput"
  ]

  connect() {
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  handleClickOutside(event) {
    if (this.element.contains(event.target)) return
    this.closeMenus()
  }

  closeMenus() {
    if (this.hasSourceMenuTarget) this.sourceMenuTarget.classList.add("hidden")
    if (this.hasTargetMenuTarget) this.targetMenuTarget.classList.add("hidden")
  }

  toggleSourceMenu(event) {
    event.stopPropagation()
    if (!this.hasSourceMenuTarget) return

    const wasHidden = this.sourceMenuTarget.classList.contains("hidden")
    this.closeMenus()

    if (wasHidden) {
      this.updateMenuSelection(this.sourceMenuTarget, this.sourceInputTarget.value)
      this.sourceMenuTarget.classList.remove("hidden")
    }
  }

  chooseSource(event) {
    const button = event.currentTarget
    const code = button.dataset.code
    const name = button.dataset.name

    const labelSpan =
      this.sourceLabelTarget.querySelector("span.truncate") ||
      this.sourceLabelTarget.querySelector("span")

    if (labelSpan) {
      labelSpan.textContent = name
    }

    this.sourceInputTarget.value = code

    this.updateMenuSelection(this.sourceMenuTarget, code)
    this.closeMenus()

    this.sourceInputTarget.dispatchEvent(
      new Event("change", { bubbles: true })
    )
  }

  toggleTargetMenu(event) {
    event.stopPropagation()
    if (!this.hasTargetMenuTarget) return

    const wasHidden = this.targetMenuTarget.classList.contains("hidden")
    this.closeMenus()

    if (wasHidden) {
      this.updateMenuSelection(this.targetMenuTarget, this.targetInputTarget.value)
      this.targetMenuTarget.classList.remove("hidden")
    }
  }

  chooseTarget(event) {
    const button = event.currentTarget
    const code = button.dataset.code
    const name = button.dataset.name

    const labelSpan =
      this.targetLabelTarget.querySelector("span.truncate") ||
      this.targetLabelTarget.querySelector("span")

    if (labelSpan) {
      labelSpan.textContent = name
    }

    this.targetInputTarget.value = code

    this.updateMenuSelection(this.targetMenuTarget, code)
    this.closeMenus()
  }

  swap(event) {
    event.stopPropagation()

    const sourceValue = this.sourceInputTarget.value
    const targetValue = this.targetInputTarget.value

    const sourceSpan =
      this.sourceLabelTarget.querySelector("span.truncate") ||
      this.sourceLabelTarget.querySelector("span")
    const targetSpan =
      this.targetLabelTarget.querySelector("span.truncate") ||
      this.targetLabelTarget.querySelector("span")

    const sourceText = sourceSpan?.textContent
    const targetText = targetSpan?.textContent

    this.sourceInputTarget.value = targetValue
    this.targetInputTarget.value = sourceValue

    if (sourceSpan && targetSpan && sourceText != null && targetText != null) {
      sourceSpan.textContent = targetText
      targetSpan.textContent = sourceText
    }

    if (this.hasSourceMenuTarget) {
      this.updateMenuSelection(this.sourceMenuTarget, this.sourceInputTarget.value)
    }
    if (this.hasTargetMenuTarget) {
      this.updateMenuSelection(this.targetMenuTarget, this.targetInputTarget.value)
    }

    this.sourceInputTarget.dispatchEvent(
      new Event("change", { bubbles: true })
    )

    this.closeMenus()
  }

  updateMenuSelection(menuEl, selectedCode) {
    if (!menuEl) return

    const buttons = menuEl.querySelectorAll("button[data-code]")
    buttons.forEach((button) => {
      const code = button.dataset.code
      const check = button.querySelector('[data-role="check"]')

      const active = code === selectedCode
      button.classList.toggle("bg-slate-50", active)
      if (check) {
        check.classList.toggle("hidden", !active)
      }
    })
  }
}
