import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: Number }
  static targets = ["up", "down"]

  connect() {
    this.isProcessing = false
  }

  upvote() { this.submitVote(1) }
  downvote() { this.submitVote(-1) }

  async submitVote(value) {
    if (this.isProcessing) return
    this.isProcessing = true

    try {
      const response = await this.sendVote(this.idValue, value)

      if (response.redirected || response.status === 401) {
        window.location = "/users/sign_in"
        return
      }

      const data = await response.json()

      this.upTarget.textContent = data.upvotes
      this.downTarget.textContent = data.downvotes

      this.applyActiveStyle(data.user_vote)

      const circle = this.element.querySelector(
        value === 1
          ? ".vote-btn-up .vote-circle, .vote-btn-up .vote-circle-sm, .vote-btn-up .vote-circle-xs"
          : ".vote-btn-down .vote-circle, .vote-btn-down .vote-circle-sm, .vote-btn-down .vote-circle-xs"
      )

      if (circle) this.animate(circle)

    } catch (err) {
      console.error("Vote failed:", err)
    } finally {
      this.isProcessing = false
    }
  }

  async sendVote(id, vote) {
    const csrf = document.querySelector("meta[name='csrf-token']")?.content || ""

    return fetch("/translation_reviews/vote", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrf
      },
      body: JSON.stringify({ id, vote })
    })
  }

  applyActiveStyle(vote) {
    const upCircle = this.element.querySelector(
      ".vote-btn-up .vote-circle, .vote-btn-up .vote-circle-sm, .vote-btn-up .vote-circle-xs"
    )
    const downCircle = this.element.querySelector(
      ".vote-btn-down .vote-circle, .vote-btn-down .vote-circle-sm, .vote-btn-down .vote-circle-xs"
    )

    if (!upCircle || !downCircle) return

    upCircle.classList.toggle("vote-active-up", vote === 1)
    downCircle.classList.toggle("vote-active-down", vote === -1)
  }

  animate(circle) {
    circle.classList.add("vote-pulse")
    setTimeout(() => circle.classList.remove("vote-pulse"), 300)
  }
}
