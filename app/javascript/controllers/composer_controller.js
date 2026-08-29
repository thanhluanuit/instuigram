import { Controller } from "@hotwired/stimulus"

// Post composer (app/views/home/_upload_form.html.erb): drives the drop zone
// behind the visually hidden file input, previews the chosen photo, mirrors the
// caption's #hashtags as chips, and keeps Share disabled until a photo is
// attached — Post requires an image but not caption text (see Post#image_presence).
export default class extends Controller {
  static targets = ["fileInput", "filename", "submit", "caption", "counter", "tags", "preview", "dropzone"]
  static values = { limit: Number }

  connect() {
    this.toggleSubmit()
    this.captionChanged()
  }

  updateFilename() {
    const file = this.fileInputTarget.files[0]
    this.filenameTarget.textContent = file ? file.name : "Drag a photo here, or click to browse"
    this.showPreview(file)
    this.toggleSubmit()
  }

  dragOver(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("is-dragging")
  }

  dragLeave() {
    this.dropzoneTarget.classList.remove("is-dragging")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("is-dragging")

    const file = event.dataTransfer.files[0]
    if (!file || !file.type.startsWith("image/")) return

    const transfer = new DataTransfer()
    transfer.items.add(file)
    this.fileInputTarget.files = transfer.files
    this.updateFilename()
  }

  captionChanged() {
    const caption = this.captionTarget.value
    this.counterTarget.textContent = `${caption.length} / ${this.limitValue}`
    this.renderTags(caption.match(/#\w+/g) || [])
  }

  renderTags(tags) {
    this.tagsTarget.replaceChildren()

    if (tags.length === 0) {
      this.tagsTarget.append(this.buildTag("add #hashtags", "composer-tag composer-tag--hint"))
      return
    }

    const unique = [...new Set(tags.map((tag) => tag.toLowerCase()))]
    unique.forEach((tag) => this.tagsTarget.append(this.buildTag(tag, "composer-tag")))
  }

  buildTag(text, className) {
    const chip = document.createElement("span")
    chip.className = className
    chip.textContent = text
    return chip
  }

  showPreview(file) {
    if (this.previewUrl) URL.revokeObjectURL(this.previewUrl)

    if (!file) {
      this.previewTarget.hidden = true
      this.previewTarget.removeAttribute("src")
      return
    }

    this.previewUrl = URL.createObjectURL(file)
    this.previewTarget.src = this.previewUrl
    this.previewTarget.hidden = false
  }

  disconnect() {
    if (this.previewUrl) URL.revokeObjectURL(this.previewUrl)
  }

  toggleSubmit() {
    this.submitTarget.disabled = this.fileInputTarget.files.length === 0
  }
}
