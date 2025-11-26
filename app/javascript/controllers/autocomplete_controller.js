import { Controller } from "@hotwired/stimulus";

const MIN_TERM_LENGTH = 2;
const DEFAULT_SOURCE_LANGUAGE = "en";
const DEBOUNCE_MS = 150;

export default class extends Controller {
  static targets = ["input", "list", "label"];

  static values = {
    url: String,
    sourceLanguage: String,
    submitOnSelect: Boolean,
    languageChangedEvent: String
  };

  connect() {
    this.selectedIndex = -1;
    this.items = [];
    this.requestId = 0;
    this.searchTimeout = null;
    this.abortController = null;

    if (!this.hasSubmitOnSelectValue) {
      this.submitOnSelectValue = false;
    }

    this._outsideClick = this.handleOutsideClick.bind(this);
    document.addEventListener("mousedown", this._outsideClick);

    if (this.hasLanguageChangedEventValue) {
      this._languageHandler = (event) => this.handleLanguageChanged(event);
      window.addEventListener(this.languageChangedEventValue, this._languageHandler);
    }
  }

  disconnect() {
    document.removeEventListener("mousedown", this._outsideClick);

    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
      this.searchTimeout = null;
    }

    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    }

    if (this._languageHandler) {
      window.removeEventListener(this.languageChangedEventValue, this._languageHandler);
      this._languageHandler = null;
    }
  }

  handleLanguageChanged(event) {
    const code = event.detail?.code;
    if (!code) return;

    this.sourceLanguageValue = code.toLowerCase();
    const languageName = this.humanizeLanguage(code);

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = this.isSourceEvent()
        ? `${languageName} Saying`
        : `Equivalent saying in ${languageName}`;
    }

    if (this.hasInputTarget) {
      this.inputTarget.placeholder = `Type a saying in ${languageName}…`;
    }
  }

  isSourceEvent() {
    return this.languageChangedEventValue === "ts:source-language-changed";
  }

  humanizeLanguage(code) {
    const map = window.LANGUAGE_CODE_TO_NAME_MAP || {};
    const key = code.toLowerCase();
    return map[key] || key.charAt(0).toUpperCase() + key.slice(1);
  }

  search() {
    const term = this.inputTarget.value.trim();
    if (term.length < MIN_TERM_LENGTH) return this.hideList();

    if (this.searchTimeout) clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => this.performSearch(term), DEBOUNCE_MS);
  }

  async performSearch(term) {
    const currentRequestId = ++this.requestId;

    if (this.abortController) this.abortController.abort();
    this.abortController = new AbortController();

    const url = new URL(this.urlValue, window.location.origin);
    url.searchParams.set("term", term);
    url.searchParams.set(
      "source_language",
      (this.sourceLanguageValue || DEFAULT_SOURCE_LANGUAGE).toLowerCase()
    );

    try {
      const res = await fetch(url.toString(), { signal: this.abortController.signal });
      if (!res.ok) return this.hideList();

      const items = await res.json();
      if (currentRequestId !== this.requestId) return;

      this.items = items;
      this.currentTerm = term;
      this.renderList();
    } catch (e) {
      if (e.name !== "AbortError") this.hideList();
    }
  }

  highlightMatch(text, term) {
    const safeTerm = term.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const regex = new RegExp(`(${safeTerm})`, "ig");
    return text.replace(regex, "<strong>$1</strong>");
  }

  renderList() {
    this.listTarget.innerHTML = "";
    if (!this.items.length) return this.hideList();

    this.items.forEach((item, index) => {
      const li = document.createElement("li");

      li.innerHTML = this.highlightMatch(item.text, this.currentTerm);
      li.className =
        "px-3 py-1.5 cursor-pointer hover:bg-sky-50 text-sm transition-colors";
      li.dataset.index = String(index);
      li.id = `autocomplete-item-${index}`;
      li.setAttribute("dir", "auto");
      li.setAttribute("role", "option");
      li.setAttribute("aria-selected", "false");

      li.addEventListener("mousedown", (event) => {
        event.preventDefault();
        this.selectIndex(index);
      });

      this.listTarget.appendChild(li);
    });

    this.listTarget.hidden = false;
    this.selectedIndex = -1;
    this.inputTarget.removeAttribute("aria-activedescendant");
  }

  handleKeydown(event) {
    if (this.listTarget.hidden) return;

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault();
        this.moveSelection(1);
        break;

      case "ArrowUp":
        event.preventDefault();
        this.moveSelection(-1);
        break;

      case "Enter":
        if (this.selectedIndex >= 0) {
          event.preventDefault();
          this.selectIndex(this.selectedIndex);
        }
        break;

      case "Escape":
        this.hideList();
        break;
    }
  }

  moveSelection(delta) {
    const maxIndex = this.items.length - 1;
    if (maxIndex < 0) return;

    this.selectedIndex += delta;
    if (this.selectedIndex < 0) this.selectedIndex = maxIndex;
    if (this.selectedIndex > maxIndex) this.selectedIndex = 0;

    Array.from(this.listTarget.children).forEach((li, idx) => {
      const selected = idx === this.selectedIndex;
      li.classList.toggle("bg-sky-50", selected);
      li.setAttribute("aria-selected", selected ? "true" : "false");
    });

    const activeId = `autocomplete-item-${this.selectedIndex}`;
    this.inputTarget.setAttribute("aria-activedescendant", activeId);
  }

  selectIndex(index) {
    const item = this.items[index];
    if (!item) return;

    this.inputTarget.value = item.text;
    this.hideList();

    if (!this.submitOnSelectValue) return;

    const form = this.element.closest("form");
    if (!form) return;

    if (form.requestSubmit) form.requestSubmit();
    else form.submit();
  }

  handleOutsideClick(event) {
    if (this.listTarget.hidden) return;
    if (this.element.contains(event.target)) return;

    this.hideList();
  }

  hideList() {
    this.listTarget.hidden = true;
    this.listTarget.innerHTML = "";
    this.selectedIndex = -1;
    this.items = [];
    this.inputTarget.removeAttribute("aria-activedescendant");
  }
}
