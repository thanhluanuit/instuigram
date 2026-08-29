import { Controller } from "@hotwired/stimulus"

const EMPTY_HINT = "Drag a photo here, or click to browse"

// Post composer (app/views/home/_upload_form.html.erb): drives the drop zone
// behind the visually hidden file input, previews the chosen photo, mirrors the
// caption's #hashtags as chips, and keeps Share disabled until a photo is
// attached — Post requires an image but not caption text (see Post#image_presence).
// acceptValue/maxBytesValue mirror ImageValidator so a file the server would
// reject never reaches it — a rejected create redirects and discards the caption.
export default class extends Controller {
  static targets = ["fileInput", "filename", "submit", "caption", "counter", "tags", "preview", "dropzone"]
  static values = { limit: Number, accept: String, maxBytes: Number }

  connect() {
    this.syncFile()
    this.captionChanged()
  }

  updateFilename() {
    this.syncFile()
  }

  syncFile() {
    const file = this.fileInputTarget.files[0]
    this.filenameTarget.textContent = file ? file.name : EMPTY_HINT
    this.showPreview(file)
    this.toggleSubmit()
  }

  dragOver(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("is-dragging")
  }

  dragLeave(event) {
    if (this.dropzoneTarget.contains(event.relatedTarget)) return

    this.dropzoneTarget.classList.remove("is-dragging")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("is-dragging")

    const file = event.dataTransfer.files[0]
    if (!this.acceptable(file)) return

    const transfer = new DataTransfer()
    transfer.items.add(file)
    this.fileInputTarget.files = transfer.files
    this.syncFile()
  }

  acceptable(file) {
    if (!file) return false

    if (!this.acceptValue.split(",").includes(file.type)) {
      this.filenameTarget.textContent = `${file.name} is not a PNG, JPEG or WebP`
      return false
    }

    if (file.size > this.maxBytesValue) {
      const megabytes = Math.floor(this.maxBytesValue / 1048576)
      this.filenameTarget.textContent = `${file.name} is larger than ${megabytes}MB`
      return false
    }

    return true
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

    new Set(tags).forEach((tag) => this.tagsTarget.append(this.buildTag(tag, "composer-tag")))
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
      this.previewUrl = null
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
    this.previewUrl = null
  }

  toggleSubmit() {
    this.submitTarget.disabled = this.fileInputTarget.files.length === 0
  }
}
