import { Controller } from "@hotwired/stimulus"

// Adds/removes repeatable fields_for rows (e.g. quote line items) using a <template>.
export default class extends Controller {
  static targets = ["item", "template"]

  add(event) {
    event.preventDefault()
    const index = new Date().getTime()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, index)
    this.itemTargetElement().insertAdjacentHTML("beforebegin", content)
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-nested-form-target='item']")
    const destroyField = item.querySelector("input[name*='_destroy']")

    if (destroyField) {
      destroyField.value = "1"
      item.classList.add("hidden")
    } else {
      item.remove()
    }
  }

  itemTargetElement() {
    return this.templateTarget
  }
}
