import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = [ "count", "icon" ]
  static values = { postId: String }

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
      this.countTarget.textContent = `${data.reactions_count} likes`
    }

    if (data.liked !== undefined && this.hasIconTarget) {
      this.updateIcon(data.liked)
    }
  }

  updateIcon(liked) {
    this.iconTarget.classList.toggle("liked", liked)
    this.iconTarget.setAttribute("aria-label", liked ? "Unlike" : "Like")
    this.iconTarget.dataset.turboMethod = liked ? "delete" : "post"
    this.iconTarget.querySelector("i").className = liked ? "fa fa-heart" : "fa fa-heart-o"
  }
}
