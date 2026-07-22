import { Controller } from "@hotwired/stimulus"

// 肉球ボタン。押した瞬間に見た目を切り替えて手触りを良くしつつ、
// 最終的な状態はサーバーが描き直したボタンに合わせる。
//
// 送信そのものは決して止めない。止める仕組みを入れると、解除に失敗したときに
// ボタンが無反応になるため。二重に送信されても結果は変わらない作りにしてある。
export default class extends Controller {
  static targets = ["button", "icon", "count"]
  static classes = ["liked", "unliked"]
  static values = { liked: Boolean }

  // 初回表示時と、サーバーがボタンを差し替えた直後に呼ばれる。
  // 常にサーバーが描いた状態を正とする。
  buttonTargetConnected(button) {
    this.likedValue = button.dataset.liked === "true"
  }

  toggle() {
    this.#apply(!this.likedValue)
    if (this.likedValue) this.#pop()
  }

  // 送信に失敗したときだけ見た目を戻す。
  // 成功時はサーバーがボタンを描き直すので、ここには通知が来ないことがある。
  settle(event) {
    if (!event.detail.success) this.#apply(!this.likedValue)
  }

  #apply(liked) {
    this.likedValue = liked
    this.countTarget.textContent = Math.max(0, Number(this.countTarget.textContent) + (liked ? 1 : -1))

    const [add, remove] = liked
      ? [this.likedClasses, this.unlikedClasses]
      : [this.unlikedClasses, this.likedClasses]
    this.buttonTarget.classList.add(...add)
    this.buttonTarget.classList.remove(...remove)

    this.iconTarget.classList.toggle("fill", liked)
    this.buttonTarget.setAttribute("aria-pressed", liked)
  }

  #pop() {
    // アニメーションは差し替えられない外側の要素で再生する
    this.element.classList.remove("paw-pop")
    void this.element.offsetWidth // 再生し直すためリフローを挟む
    this.element.classList.add("paw-pop")
  }
}
