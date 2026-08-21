import {Controller} from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = {postId: Number}

  connect() {
    this.subscription = consumer.subscriptions.create(
      {channel: "PostChannel", id: this.postIdValue},
      {
        received: (data) => {
          this.element.textContent = `${data.reactions_count} likes`
        }
      }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }
}
