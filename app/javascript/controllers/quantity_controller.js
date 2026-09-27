import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  increment() {
    this.inputTarget.value = parseInt(this.inputTarget.value || "1", 10) + 1
    this.dispatchChange()
  }

  decrement() {
    const next = parseInt(this.inputTarget.value || "1", 10) - 1
    this.inputTarget.value = Math.max(1, next)
    this.dispatchChange()
  }

  dispatchChange() {
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
