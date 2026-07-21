import { Controller } from "@hotwired/stimulus"

// 肉球ボタン。サーバーの応答を待たずに見た目と件数を切り替え、
// 送信が失敗したときだけ元の状態へ戻す。
export default class extends Controller {
  static targets = ["button", "icon", "count", "method"]
  static classes = ["liked", "unliked"]
  static values = { liked: Boolean }

  toggle() {
    this.likedValue = !this.likedValue
    this.countTarget.textContent = Number(this.countTarget.textContent) + (this.likedValue ? 1 : -1)
    this.#render()
    if (this.likedValue) this.#pop()
  }

  // 通信に失敗したら見た目を戻す（成功時はすでに正しい状態なので何もしない）
  settle(event) {
    if (event.detail.success) return

    this.likedValue = !this.likedValue
    this.countTarget.textContent = Number(this.countTarget.textContent) + (this.likedValue ? 1 : -1)
    this.#render()
  }

  #render() {
    const [add, remove] = this.likedValue
      ? [this.likedClasses, this.unlikedClasses]
      : [this.unlikedClasses, this.likedClasses]

    this.buttonTarget.classList.add(...add)
    this.buttonTarget.classList.remove(...remove)
    this.iconTarget.classList.toggle("fill", this.likedValue)
    this.buttonTarget.setAttribute("aria-pressed", this.likedValue)
    // 次の送信先（いいね／取り消し）を切り替える
    this.methodTarget.value = this.likedValue ? "delete" : "post"
  }

  #pop() {
    this.iconTarget.classList.remove("paw-pop")
    void this.iconTarget.offsetWidth // アニメーションを再生し直すためリフローを挟む
    this.iconTarget.classList.add("paw-pop")
  }
}
