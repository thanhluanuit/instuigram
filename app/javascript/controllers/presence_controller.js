import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "PresenceChannel" },
      { received: this.received.bind(this) }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }

  received(data) {
    document.querySelectorAll(`[data-presence-user-id="${data.user_id}"]`).forEach((dot) => {
      dot.classList.toggle("is-online", data.online)
    })

    document.querySelectorAll(`[data-presence-status-for="${data.user_id}"]`).forEach((label) => {
      label.textContent = data.online ? "Active now" : "Offline"
    })
  }
}
