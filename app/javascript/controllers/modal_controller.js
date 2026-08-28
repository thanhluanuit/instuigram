import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    document.body.classList.add("modal-open")
  }

  disconnect() {
    document.body.classList.remove("modal-open")
  }

  close() {
    const frame = this.element.closest("turbo-frame")
    frame.removeAttribute("src")
    frame.replaceChildren()
  }

  closeOnBackdrop(event) {
    if (event.target === this.element) this.close()
  }
}
