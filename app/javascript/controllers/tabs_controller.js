import { Controller } from "@hotwired/stimulus"

// Vanilla replacement for Bootstrap 4's data-toggle="pill" vertical tabs
// (app/views/profiles/edit.html.erb). Toggles .active on the clicked tab and
// the .tab-pane whose id matches the tab's href.
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
