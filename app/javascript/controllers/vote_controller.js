import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: Number }
  static targets = ["up", "down"]

  connect() {
    this.isProcessing = false
  }

  upvote() {
    this.submitVote(1)
  }

  downvote() {
    this.submitVote(-1)
  }

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

      // update counts
      this.upTarget.textContent = data.upvotes
      this.downTarget.textContent = data.downvotes

      // update active styling
      this.applyActiveStyle(data.user_vote)

      // animate selected button
      const circle = value === 1
        ? this.element.querySelector(".vote-btn-up .vote-circle")
        : this.element.querySelector(".vote-btn-down .vote-circle")

      this.animate(circle)
    } catch (err) {
      console.error("Vote failed:", err)
    } finally {
      this.isProcessing = false
    }
  }

  async sendVote(id, vote) {
    const csrfMeta = document.querySelector("meta[name='csrf-token']");
    const csrf = csrfMeta ? csrfMeta.content : "";

    return fetch("/translation_reviews/vote", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrf
      },
      body: JSON.stringify({ id, vote })
    });
  }
  applyActiveStyle(vote) {
    const upCircle = this.element.querySelector(".vote-btn-up .vote-circle")
    const downCircle = this.element.querySelector(".vote-btn-down .vote-circle")

    upCircle.classList.toggle("vote-active-up", vote === 1)
    downCircle.classList.toggle("vote-active-down", vote === -1)
  }

  animate(circle) {
    circle.classList.add("vote-animate")
    setTimeout(() => circle.classList.remove("vote-animate"), 300)
  }
}
