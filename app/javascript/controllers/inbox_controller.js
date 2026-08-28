import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "InboxChannel" },
      { received: this.received.bind(this) }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }

  received(data) {
    this.updateBadge(data.total_unread)
    this.updateRow(data)
  }

  updateBadge(total) {
    const badge = document.getElementById("unread-badge")
    if (!badge) return

    badge.textContent = total
    badge.classList.toggle("is-hidden", total === 0)
  }

  updateRow(data) {
    const row = document.getElementById(`conversation_${data.conversation_id}`)
    if (!row) return

    const sender = row.querySelector(".conversation-row__sender")
    const text = row.querySelector(".conversation-row__text")
    const unread = row.querySelector(".conversation-row__unread")

    if (sender) sender.textContent = `${data.sender}:`
    if (text) text.textContent = data.preview

    if (unread) {
      unread.textContent = data.unread_count
      unread.classList.toggle("is-hidden", data.unread_count === 0)
    }

    row.parentNode.prepend(row)
  }
}
