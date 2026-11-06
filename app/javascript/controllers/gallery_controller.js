import { Controller } from "@hotwired/stimulus"

// Swaps which screenshot the big figure shows. Without JavaScript the first
// screenshot stays visible and the thumbnails simply do nothing, so the page
// still tells the whole story.
export default class extends Controller {
  static targets = ["slide", "thumb"]

  select({ params: { index } }) {
    this.slideTargets.forEach((slide, i) => slide.toggleAttribute("hidden", i !== index))

    this.thumbTargets.forEach((thumb, i) => {
      const active = i === index
      thumb.setAttribute("aria-pressed", active)
      thumb.style.borderColor = active ? thumb.dataset.galleryAccent || "" : ""
    })
  }
}
