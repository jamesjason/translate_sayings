import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "startScreen", "noItemsCard", "card", "completeCard",
    "languageAInput", "languageBInput",
    "languageALabel", "languageAMenu",
    "languageBLabel", "languageBMenu",
    "progressWrapper", "progressText", "progressBar",
    "sayingA", "sayingB",
    "upvoteBtn", "downvoteBtn",
    "upvoteCount", "downvoteCount",
    "prevBtn", "nextBtn"
  ]

  static values = {
    itemsUrl: String,
    currentIndex: Number
  }

  connect() {
    this.items = []
    this.state = "start"
    this.isTransitioning = false

    this.showStart()
    document.addEventListener("click", this.closeMenus)
  }

  disconnect() {
    document.removeEventListener("click", this.closeMenus)
  }

  // =============================
  // SCREEN STATES
  // =============================

  showStart() {
    this.state = "start"
    this.toggleScreens({ start: true })
  }

  showReview() {
    this.state = "review"
    this.toggleScreens({ card: true, progress: true })
  }

  showNoItems() {
    this.state = "no_items"
    this.toggleScreens({ noItems: true })
  }

  showThankYou() {
    this.state = "thank_you"
    this.toggleScreens({ complete: true, progress: true })
    this.updateNavigation()
  }

  toggleScreens({ start = false, card = false, noItems = false, complete = false, progress = false }) {
    this.startScreenTarget.classList.toggle("hidden", !start)
    this.cardTarget.classList.toggle("hidden", !card)
    this.noItemsCardTarget.classList.toggle("hidden", !noItems)
    this.completeCardTarget.classList.toggle("hidden", !complete)
    this.progressWrapperTarget.classList.toggle("hidden", !progress)
  }

  // =============================
  // DATA
  // =============================

  async start() {
    await this.loadItems()

    if (this.items.length === 0) return this.showNoItems()

    this.currentIndexValue = 0
    this.showReview()
    this.render()
  }

  async loadNewItems() {
    await this.start()
  }

  async loadItems() {
    const a = this.languageAInputTarget.value
    const b = this.languageBInputTarget.value

    try {
      const response = await fetch(`${this.itemsUrlValue}?language_a_code=${a}&language_b_code=${b}`)
      const data = await response.json()
      this.items = data.translations || []
    } catch (err) {
      console.error("Failed to load items:", err)
      this.items = []
    }
  }

  // =============================
  // RENDER
  // =============================

  render() {
    const i = this.currentIndexValue

    if (i >= this.items.length) return this.showThankYou()

    const item = this.items[i]

    this.resetVoteStyles()

    this.sayingATarget.textContent = item.saying_a
    this.sayingBTarget.textContent = item.saying_b
    this.upvoteCountTarget.textContent = item.upvotes
    this.downvoteCountTarget.textContent = item.downvotes

    this.updateProgress(i)
    this.updateVoteStyles(item.user_vote)
    this.updateNavigation()
  }

  updateProgress(i) {
    const total = this.items.length
    this.progressTextTarget.textContent = `${i + 1} / ${total}`
    this.progressBarTarget.style.width = `${((i + 1) / total) * 100}%`
  }

  updateNavigation() {
    const i = this.currentIndexValue

    this.prevBtnTarget.disabled = i === 0
    this.nextBtnTarget.disabled = false
  }

  // =============================
  // VOTING
  // =============================

  voteUp() { this.submitVote(1) }
  voteDown() { this.submitVote(-1) }

  async submitVote(value) {
    const item = this.items[this.currentIndexValue]
    this.disableVoting()

    try {
      const data = await this.sendVote(item.id, value)

      item.upvotes = data.upvotes
      item.downvotes = data.downvotes
      item.user_vote = data.user_vote

      this.render()
      this.animateVote(value)

      setTimeout(async () => {
        await this.goNext()
        this.enableVoting()
      }, 450)

    } catch (err) {
      console.error("Vote failed:", err)
      this.enableVoting()
    }
  }

  async sendVote(id, vote) {
    const csrf = document.querySelector("meta[name='csrf-token']").content

    const response = await fetch("/translation_reviews/vote", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf },
      body: JSON.stringify({ id, vote })
    })

    if (response.redirected || response.status === 401) {
      window.location = "/users/sign_in"
      throw new Error("Redirect to login")
    }

    return response.json()
  }

  resetVoteStyles() {
    this.upvoteBtnTarget.querySelector(".vote-circle")
      .classList.remove("vote-active-up", "vote-animate")

    this.downvoteBtnTarget.querySelector(".vote-circle")
      .classList.remove("vote-active-down", "vote-animate")
  }

  updateVoteStyles(vote) {
    this.upvoteBtnTarget.querySelector(".vote-circle")
      .classList.toggle("vote-active-up", vote === 1)

    this.downvoteBtnTarget.querySelector(".vote-circle")
      .classList.toggle("vote-active-down", vote === -1)
  }

  animateVote(value) {
    const circle = value === 1
      ? this.upvoteBtnTarget.querySelector(".vote-circle")
      : this.downvoteBtnTarget.querySelector(".vote-circle")

    circle.classList.add("vote-animate")
    setTimeout(() => circle.classList.remove("vote-animate"), 300)
  }

  disableVoting() {
    this.upvoteBtnTarget.disabled = true
    this.downvoteBtnTarget.disabled = true
  }

  enableVoting() {
    this.upvoteBtnTarget.disabled = false
    this.downvoteBtnTarget.disabled = false
  }

  // =============================
  // NAVIGATION
  // =============================

  async goNext() {
    if (this.isTransitioning) return
    this.isTransitioning = true

    this.resetVoteStyles()
    await this.slide(-1)

    this.currentIndexValue++
    this.render()

    this.isTransitioning = false
  }

  async goPrev() {
    if (this.isTransitioning) return
    this.isTransitioning = true

    this.resetVoteStyles()
    await this.slide(1)

    this.currentIndexValue--
    this.render()

    this.isTransitioning = false
  }

  slide(direction) {
    return new Promise(resolve => {
      this.cardTarget.style.transform = `translateX(${direction * 40}px)`
      this.cardTarget.style.opacity = "0"

      setTimeout(() => {
        this.cardTarget.style.transition = "none"
        this.cardTarget.style.transform = `translateX(${direction * -40}px)`

        setTimeout(() => {
          this.cardTarget.style.transition = "all 300ms ease"
          this.cardTarget.style.transform = "translateX(0)"
          this.cardTarget.style.opacity = "1"
          resolve()
        }, 20)
      }, 250)
    })
  }

  // =============================
  // LANGUAGE DROPDOWNS
  // =============================

  closeMenus = (e) => {
    if (!this.element.contains(e.target)) {
      this.languageAMenuTarget.classList.add("hidden")
      this.languageBMenuTarget.classList.add("hidden")
    }
  }

  toggleLanguageAMenu(e) {
    e.stopPropagation()
    this.languageAMenuTarget.classList.toggle("hidden")
    this.languageBMenuTarget.classList.add("hidden")
  }

  toggleLanguageBMenu(e) {
    e.stopPropagation()
    this.languageBMenuTarget.classList.toggle("hidden")
    this.languageAMenuTarget.classList.add("hidden")
  }

  chooseLanguageA(e) { this.chooseLanguage(e, "A") }
  chooseLanguageB(e) { this.chooseLanguage(e, "B") }

  chooseLanguage(e, which) {
    const code = e.currentTarget.dataset.code
    const name = e.currentTarget.dataset.name

    const input  = which === "A" ? this.languageAInputTarget : this.languageBInputTarget
    const label  = which === "A" ? this.languageALabelTarget : this.languageBLabelTarget
    const menu   = which === "A" ? this.languageAMenuTarget : this.languageBMenuTarget

    input.value = code
    label.querySelector("span").textContent = name

    menu.querySelectorAll("[role='option']").forEach(option => {
      const selected = option.dataset.code === code

      option.setAttribute("aria-selected", selected)
      option.querySelector("[data-role='check']").classList.toggle("hidden", !selected)
      option.classList.toggle("bg-slate-50", selected)
    })

    menu.classList.add("hidden")
  }

  returnToLanguageSelection() {
    this.showStart()
    this.currentIndexValue = 0
    this.items = []
  }
}
