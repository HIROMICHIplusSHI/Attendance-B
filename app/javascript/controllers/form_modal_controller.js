import { Controller } from "@hotwired/stimulus"

// 単一フォーム用モーダルコントローラー（申請・編集・作成用）
// 対象: application_requests, offices, users/edit_basic_info など
export default class extends Controller {
  static targets = ["container", "content"]

  connect() {
    // Form modal controller connected
  }

  // モーダルを開く
  async open(event) {
    event.preventDefault()
    const url = event.currentTarget.href

    try {
      const response = await fetch(url, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.csrfToken
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const html = await response.text()
      this.contentTarget.innerHTML = html
      this.containerTarget.style.display = 'block'

      // フォーム送信イベントをハンドリング
      this.setupFormSubmit()

      // 閉じるボタンの処理
      this.setupCloseButton()
    } catch (error) {
      console.error('Error loading modal:', error)
      alert('モーダルの読み込みに失敗しました')
    }
  }

  // モーダルを閉じる
  close() {
    this.containerTarget.style.display = 'none'
    this.contentTarget.innerHTML = ''
  }

  // 背景クリックで閉じる
  backgroundClick(event) {
    if (event.target === this.containerTarget) {
      this.close()
    }
  }

  // フォーム送信処理のセットアップ
  setupFormSubmit() {
    const form = this.contentTarget.querySelector('form')
    if (!form) return

    // Ajaxでバリデーションのみ実行（保存はしない）
    form.addEventListener('submit', (e) => {
      e.preventDefault()
      this.submitForm(form)
    })
  }

  // フォーム送信（バリデーションのみ）
  async submitForm(form) {
    const formData = new FormData(form)

    try {
      const response = await fetch(form.action, {
        method: form.method.toUpperCase(),
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.csrfToken,
          'Accept': 'text/html'
        }
      })

      const html = await response.text()

      if (response.ok) {
        // バリデーション成功時
        this.handleSuccess(form)
      } else {
        // バリデーションエラー時
        this.handleError(html)
      }
    } catch (error) {
      console.error('Form submission error:', error)
      alert('送信に失敗しました')
    }
  }

  // 成功時の処理
  handleSuccess(form) {
    // 確認ダイアログが必要な場合
    if (form.dataset.confirm === 'true') {
      const message = form.dataset.confirmMessage || 'この内容で更新してよろしいですか？'
      if (confirm(message)) {
        // 通常のフォーム送信（リダイレクト＋flash表示のため）
        form.submit()
      }
    } else {
      // 確認不要の場合は通常のフォーム送信でリダイレクト
      form.submit()
    }
  }

  // エラー時の処理
  handleError(html) {
    // モーダル内容を更新してエラー表示
    this.contentTarget.innerHTML = html

    // 再度フォーム送信イベントを設定
    this.setupFormSubmit()
    this.setupCloseButton()
  }

  // 閉じるボタンのセットアップ
  setupCloseButton() {
    const closeBtn = this.contentTarget.querySelector('.btn-close, [data-dismiss="modal"]')
    if (closeBtn) {
      closeBtn.addEventListener('click', () => this.close())
    }
  }

  // CSRFトークン取得
  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  }
}
