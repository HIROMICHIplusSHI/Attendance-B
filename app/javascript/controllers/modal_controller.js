import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["container", "content"]

  connect() {
    // Modal controller connected
  }

  // ダミーモーダルを開く
  openDummy(event) {
    event.preventDefault()
    const title = event.currentTarget.dataset.dummyTitle || '未実装機能'

    const dummyHtml = `
      <div class="modal-header">
        <h4 class="modal-title">${title}</h4>
        <button type="button" class="close" data-action="modal#close">×</button>
      </div>
      <div class="modal-body">
        <p>この機能は現在未実装です。</p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-action="modal#close">閉じる</button>
      </div>
    `

    this.contentTarget.innerHTML = dummyHtml
    this.containerTarget.style.display = 'block'
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

    // data-remote="true" が明示的に設定されている場合のみカスタム処理
    // local: true のフォームはdata-remote属性を持たないため、通常のフォーム送信になる
    const isRemote = form.getAttribute('data-remote') === 'true'
    if (!isRemote) {
      // local: true のフォームにもバリデーションを追加
      this.setupApprovalValidation(form)
      return
    }

    // Ajaxフォーム送信（remote: true）を使用
    form.addEventListener('submit', (e) => {
      e.preventDefault()
      this.submitForm(form)
    })
  }

  // 承認フォームのバリデーション
  setupApprovalValidation(form) {
    // 承認フォームかどうかを判定（bulk_update パスが含まれる場合）
    if (!form.action.includes('bulk_update')) return

    // エラー表示エリアを取得
    const errorArea = form.querySelector('#validation-errors')

    // submit イベントで確認ダイアログより前にバリデーション
    form.addEventListener('submit', (e) => {
      // エラーメッセージをクリア
      if (errorArea) {
        errorArea.style.display = 'none'
        errorArea.textContent = ''
      }

      // チェックされた項目を取得
      const checkboxes = form.querySelectorAll('input[type="checkbox"][name*="[selected]"]:checked')

      if (checkboxes.length === 0) {
        e.preventDefault()
        e.stopImmediatePropagation()
        this.showValidationError(errorArea, '変更する項目にチェックを入れてください')
        return false
      }

      // チェックされた項目の承認/否認が選択されているかを確認
      let hasError = false
      checkboxes.forEach(checkbox => {
        const requestId = checkbox.name.match(/requests\[(\d+)\]/)[1]
        const statusSelect = form.querySelector(`select[name="requests[${requestId}][status]"]`)

        if (statusSelect && statusSelect.value === 'pending') {
          hasError = true
        }
      })

      if (hasError) {
        e.preventDefault()
        e.stopImmediatePropagation()
        this.showValidationError(errorArea, 'チェックした項目の承認/否認を選択してください')
        return false
      }
    }, true) // キャプチャフェーズで実行
  }

  // バリデーションエラーを表示
  showValidationError(errorArea, message) {
    if (errorArea) {
      errorArea.textContent = message
      errorArea.style.display = 'block'
      // エラーエリアまでスクロール
      errorArea.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }
  }

  // フォーム送信
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
        this.handleSuccess(html, form)
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
  handleSuccess(html, form) {
    // 確認ダイアログが必要な場合（data-confirm属性で判定）
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
