import { Controller } from "@hotwired/stimulus"

const MIN_TERM_LENGTH = 2
const DEFAULT_SOURCE_LANGUAGE = "en"
const DEBOUNCE_MS = 150

export default class extends Controller {
  static values = {
    url: String,
    sourceLanguage: String,
  }

  static targets = ["input", "list"]

  connect() {
    this.selectedIndex = -1
    this.items = []
    this.requestId = 0
    this.searchTimeout = null
  }

  disconnect() {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
      this.searchTimeout = null
    }
  }

  setSourceLanguage(event) {
    this.sourceLanguageValue = event.target.value.toLowerCase()
    this.hideList()
  }

  search() {
    const term = this.inputTarget.value.trim()
    if (term.length < MIN_TERM_LENGTH) {
      this.hideList()
      return
    }

    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    this.searchTimeout = setTimeout(() => {
      this.performSearch(term)
    }, DEBOUNCE_MS)
  }

  async performSearch(term) {
    const currentRequestId = ++this.requestId

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("term", term)
    url.searchParams.set(
      "source_language",
      (this.sourceLanguageValue || DEFAULT_SOURCE_LANGUAGE).toLowerCase()
    )

    try {
      const res = await fetch(url.toString())
      if (!res.ok) {
        this.hideList()
        return
      }

      const items = await res.json()

      if (currentRequestId !== this.requestId) return

      this.items = items
      this.renderList()
    } catch (error) {
      this.hideList()
    }
  }

  renderList() {
    const list = this.listTarget
    list.innerHTML = ""

    if (!this.items.length) {
      this.hideList()
      return
    }

    this.items.forEach((item, index) => {
      const li = document.createElement("li")
      li.textContent = item.text
      li.className = "px-3 py-1.5 cursor-pointer hover:bg-slate-100 text-sm"
      li.dataset.index = String(index)
      li.setAttribute("dir", "auto")
      li.setAttribute("role", "option")

      li.addEventListener("mousedown", (event) => {
        event.preventDefault()
        this.selectIndex(index)
      })

      list.appendChild(li)
    })

    list.hidden = false
    list.setAttribute("role", "listbox")
    this.selectedIndex = -1
  }

  handleKeydown(event) {
    if (this.listTarget.hidden) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.moveSelection(1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.moveSelection(-1)
    } else if (event.key === "Enter") {
      if (this.selectedIndex >= 0) {
        event.preventDefault()
        this.selectIndex(this.selectedIndex)
      }
    } else if (event.key === "Escape") {
      this.hideList()
    }
  }

  moveSelection(delta) {
    const maxIndex = this.items.length - 1
    if (maxIndex < 0) return

    this.selectedIndex += delta
    if (this.selectedIndex < 0) this.selectedIndex = maxIndex
    if (this.selectedIndex > maxIndex) this.selectedIndex = 0

    Array.from(this.listTarget.children).forEach((li, idx) => {
      li.classList.toggle("bg-slate-100", idx === this.selectedIndex)
    })
  }

  selectIndex(index) {
    const item = this.items[index]
    if (!item) return

    this.inputTarget.value = item.text
    this.hideList()

    const form = this.element.closest("form") || this.element
    if (form && typeof form.requestSubmit === "function") {
      form.requestSubmit()
    } else if (form) {
      form.submit()
    }
  }

  hideList() {
    this.listTarget.hidden = true
    this.listTarget.innerHTML = ""
    this.selectedIndex = -1
    this.items = []
  }
}
