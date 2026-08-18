import { Controller } from "@hotwired/stimulus"

// Post composer (app/views/home/_upload_form.html.erb): shows the chosen
// photo's filename since the file input is visually hidden behind an icon
// button, and keeps Post disabled until a photo is attached — Post requires
// an image but not caption text (see Post#image_presence).
export default class extends Controller {
  static targets = ["fileInput", "filename", "submit"]

  connect() {
    this.toggleSubmit()
  }

  updateFilename() {
    const file = this.fileInputTarget.files[0]
    this.filenameTarget.textContent = file ? file.name : "No photo selected"
    this.toggleSubmit()
  }

  toggleSubmit() {
    this.submitTarget.disabled = this.fileInputTarget.files.length === 0
  }
}
