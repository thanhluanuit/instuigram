import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "pane"]

  select(event) {
    event.preventDefault()
    const paneId = event.currentTarget.getAttribute("href").slice(1)

    this.tabTargets.forEach((tab) => tab.classList.toggle("active", tab === event.currentTarget))
    this.paneTargets.forEach((pane) => {
      const isSelected = pane.id === paneId
      pane.classList.toggle("active", isSelected)
      pane.classList.toggle("show", isSelected)
    })
  }
}
