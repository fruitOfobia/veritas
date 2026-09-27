import { Controller } from "@hotwired/stimulus"

// Searchable product picker for the quote request form. Types into a visible
// text field, picks from a fetched dropdown, and stores the chosen product's id
// in a hidden field so the form submits exactly as the old <select> did.
export default class extends Controller {
  static targets = ["input", "hidden", "results"]
  static values = { url: String }

  connect() {
    this.debounceTimer = null
    this.activeIndex = -1
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
    document.addEventListener("click", this.closeOnClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
    clearTimeout(this.debounceTimer)
  }

  search() {
    // Typing invalidates any previous pick until a new one is chosen.
    this.hiddenTarget.value = ""
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.fetchOptions(this.inputTarget.value.trim()), 200)
  }

  onFocus() {
    this.fetchOptions(this.inputTarget.value.trim())
  }

  async fetchOptions(query) {
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: { Accept: "application/json" }
      })
      if (!response.ok) return

      this.render(await response.json())
    } catch (error) {
      // Network hiccup — leave the dropdown alone rather than breaking the form.
    }
  }

  render(products) {
    if (products.length === 0) {
      this.resultsTarget.innerHTML =
        '<p class="px-3 py-4 text-sm text-ink-400 text-center">No matching products</p>'
      this.open()
      return
    }

    this.resultsTarget.innerHTML = products
      .map(
        (product) => `
        <button type="button" data-action="product-picker#choose"
                data-product-id="${product.id}" data-product-name="${this.escape(product.name)}"
                class="flex w-full items-center justify-between gap-3 px-3 py-2 text-left hover:bg-ink-50">
          <span class="min-w-0">
            <span class="block truncate text-sm font-medium text-ink-800">${this.escape(product.name)}</span>
            <span class="block text-xs text-ink-400">${this.escape(product.category)}</span>
          </span>
          <span class="shrink-0 text-sm font-semibold text-ink-900">${this.escape(product.price)}</span>
        </button>`
      )
      .join("")

    this.activeIndex = -1
    this.open()
  }

  choose(event) {
    const option = event.currentTarget
    this.hiddenTarget.value = option.dataset.productId
    this.inputTarget.value = option.dataset.productName
    this.close()
  }

  onKeydown(event) {
    if (event.key === "Escape") {
      this.close()
      return
    }

    const options = this.optionElements()
    if (options.length === 0) return

    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const step = event.key === "ArrowDown" ? 1 : -1
      this.activeIndex = (this.activeIndex + step + options.length) % options.length
      this.highlight(options)
    } else if (event.key === "Enter" && this.activeIndex >= 0) {
      // Pick the highlighted option instead of submitting the whole form.
      event.preventDefault()
      options[this.activeIndex].click()
    }
  }

  highlight(options) {
    options.forEach((option, index) => option.classList.toggle("bg-ink-50", index === this.activeIndex))
    options[this.activeIndex]?.scrollIntoView({ block: "nearest" })
  }

  optionElements() {
    return Array.from(this.resultsTarget.querySelectorAll("button[data-product-id]"))
  }

  open() {
    this.resultsTarget.classList.remove("hidden")
  }

  close() {
    this.resultsTarget.classList.add("hidden")
    this.activeIndex = -1
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  escape(value) {
    const div = document.createElement("div")
    div.textContent = value == null ? "" : String(value)
    return div.innerHTML
  }
}
