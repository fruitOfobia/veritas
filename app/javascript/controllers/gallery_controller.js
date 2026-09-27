import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["main", "thumb"]

  select(event) {
    const url = event.currentTarget.dataset.fullUrl
    this.mainTarget.src = url

    this.thumbTargets.forEach((thumb) => thumb.classList.remove("ring-2", "ring-brand-500"))
    event.currentTarget.classList.add("ring-2", "ring-brand-500")
  }
}
