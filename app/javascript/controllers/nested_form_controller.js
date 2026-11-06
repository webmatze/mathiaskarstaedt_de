import { Controller } from "@hotwired/stimulus"

// Adds another row to a nested-attributes section. The blank row lives in a
// <template> rendered by Rails, so the markup never has to be duplicated in JS.
export default class extends Controller {
  static targets = ["list", "template"]

  add() {
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now().toString())
    this.listTarget.insertAdjacentHTML("beforeend", html)
  }
}
