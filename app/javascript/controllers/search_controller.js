import { Controller } from "@hotwired/stimulus"

// Live "search as you type" dropdown under the header search box. Debounces
// keystrokes, fetches a small HTML fragment of matching products/categories,
// and supports basic keyboard navigation.
export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String }

  connect() {
    this.debounceTimer = null
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
    document.addEventListener("click", this.closeOnClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
    clearTimeout(this.debounceTimer)
  }

  search() {
    const query = this.inputTarget.value.trim()
    clearTimeout(this.debounceTimer)

    if (query.length < 2) {
      this.close()
      return
    }

    this.debounceTimer = setTimeout(() => this.fetchResults(query), 250)
  }

  async fetchResults(query) {
    const url = `${this.urlValue}?q=${encodeURIComponent(query)}`

    try {
      const response = await fetch(url, { headers: { Accept: "text/html" } })
      if (!response.ok) return

      this.resultsTarget.innerHTML = await response.text()
      this.open()
    } catch (error) {
      // Network hiccup — leave the dropdown as-is rather than breaking the page.
    }
  }

  open() {
    this.resultsTarget.classList.remove("hidden")
  }

  close() {
    this.resultsTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  onFocus() {
    if (this.inputTarget.value.trim().length >= 2 && this.resultsTarget.innerHTML.trim() !== "") {
      this.open()
    }
  }

  onKeydown(event) {
    if (event.key === "Escape") {
      this.close()
      this.inputTarget.blur()
      return
    }

    if (event.key !== "ArrowDown" && event.key !== "ArrowUp") return
    const items = Array.from(this.resultsTarget.querySelectorAll('[data-search-target="item"]'))
    if (items.length === 0) return

    event.preventDefault()
    const currentIndex = items.indexOf(document.activeElement)
    let nextIndex

    if (event.key === "ArrowDown") {
      nextIndex = currentIndex + 1 >= items.length ? 0 : currentIndex + 1
    } else {
      nextIndex = currentIndex - 1 < 0 ? items.length - 1 : currentIndex - 1
    }

    items[nextIndex].focus()
  }
}
