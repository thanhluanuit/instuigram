import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = [ "list", "input" ]
  static values = { conversationId: Number, currentUserId: Number, readUrl: String }

  connect() {
    this.markOwnMessages()
    this.scrollToBottom()

    this.observer = new MutationObserver(() => {
      this.markOwnMessages()
      this.scrollToBottom()
    })
    this.observer.observe(this.listTarget, { childList: true })

    this.subscription = consumer.subscriptions.create(
      { channel: "ConversationChannel", id: this.conversationIdValue },
      { received: this.received.bind(this) }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.observer?.disconnect()
  }

  received(data) {
    const id = data.match(/id="(message_\d+)"/)?.[1]
    if (id && document.getElementById(id)) return

    window.Turbo.renderStreamMessage(data)
    this.markRead()
  }

  clearComposer() {
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  markOwnMessages() {
    this.listTarget.querySelectorAll(".chat-message").forEach((element) => {
      const mine = Number(element.dataset.senderId) === this.currentUserIdValue
      element.classList.toggle("chat-message--mine", mine)
    })
  }

  scrollToBottom() {
    this.listTarget.scrollTop = this.listTarget.scrollHeight
  }

  markRead() {
    fetch(this.readUrlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content }
    })
  }
}
