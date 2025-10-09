import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapse"
export default class extends Controller {
  static targets = ["content"]

  connect() {
    // Collapse controller connected
  }

  toggle(event) {
    event.preventDefault()
    const content = this.contentTarget

    if (content.style.display === "none" || content.style.display === "") {
      content.style.display = "block"
    } else {
      content.style.display = "none"
    }
  }
}
