import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Feed post footer (app/views/posts/_post_footer.html.erb): like/unlike +
// live reaction count. Separate from reactions_controller.js (post detail's
// icon-only button) since the two partials' markup differs.
export default class extends Controller {
  static targets = ["button", "label", "count"]
  static values = { postId: Number }

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "PostChannel", id: this.postIdValue },
      { received: this.received.bind(this) }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }

  received(data) {
    if (data.reactions_count !== undefined) {
      this.countTarget.textContent = `${data.reactions_count} reaction${data.reactions_count === 1 ? "" : "s"}`
    }

    if (data.liked !== undefined) {
      this.updateButton(data.liked)
    }
  }

  updateButton(liked) {
    this.buttonTarget.classList.toggle("liked", liked)
    this.buttonTarget.setAttribute("aria-label", liked ? "Unlike" : "Like")
    this.buttonTarget.dataset.turboMethod = liked ? "delete" : "post"
    this.labelTarget.textContent = liked ? "Unlike" : "Like"
  }
}
