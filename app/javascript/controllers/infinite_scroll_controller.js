import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner", "link"]
  static values = { url: String }

  connect() {
    this.observer = new IntersectionObserver(this.load.bind(this), { rootMargin: "200px" })
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  async load(entries) {
    if (!entries.some((entry) => entry.isIntersecting) || this.loading) return

    this.loading = true
    this.observer.disconnect()
    this.spinnerTarget.hidden = false
    this.linkTarget.hidden = true

    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "text/vnd.turbo-stream.html" }
      })

      if (!response.ok) throw new Error(`Failed to load more posts: ${response.status}`)

      Turbo.renderStreamMessage(await response.text())
    } catch (error) {
      console.error(error)
      this.spinnerTarget.hidden = true
      this.linkTarget.hidden = false
      this.loading = false
      this.observer.observe(this.element)
    }
  }
}
