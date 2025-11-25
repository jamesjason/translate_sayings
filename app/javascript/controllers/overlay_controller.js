import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]
  static values = { active: Boolean }

  connect() {
    this._hideTimeout = null
    if (this.activeValue) this.show()
  }

  disconnect() {
    if (this._hideTimeout) clearTimeout(this._hideTimeout)
  }

  show() {
    if (!this.hasPanelTarget) return

    this.panelTarget.classList.remove("hidden", "opacity-0")
    this.panelTarget.classList.add("opacity-100")

    if (this._hideTimeout) clearTimeout(this._hideTimeout)
    this._hideTimeout = setTimeout(() => this.hide(), 3000)
  }

  hide() {
    if (!this.hasPanelTarget) return

    this.panelTarget.classList.remove("opacity-100")
    this.panelTarget.classList.add("opacity-0")

    setTimeout(() => {
      if (this.panelTarget.classList.contains("opacity-0")) {
        this.panelTarget.classList.add("hidden")
      }
    }, 200)
  }
}
