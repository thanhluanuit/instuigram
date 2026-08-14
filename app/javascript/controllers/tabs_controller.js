import { Controller } from "@hotwired/stimulus"

// Vanilla replacement for Bootstrap 4's data-toggle="pill" vertical tabs
// (app/views/users/edit.html.erb). Toggles .active on the clicked tab and
// its matching .tab-pane by index.
export default class extends Controller {
  static targets = ["tab", "pane"]

  select(event) {
    event.preventDefault()
    const index = this.tabTargets.indexOf(event.currentTarget)

    this.tabTargets.forEach((tab, i) => tab.classList.toggle("active", i === index))
    this.paneTargets.forEach((pane, i) => {
      pane.classList.toggle("active", i === index)
      pane.classList.toggle("show", i === index)
    })
  }
}
