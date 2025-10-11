import { Controller } from "@hotwired/stimulus"
import { ErrorHandler } from "utils/error_handler"

// 一括更新用モーダルコントローラー（承認用）
// 対象: overtime_approvals, monthly_approvals, attendance_change_approvals など
export default class extends Controller {
  static targets = ["container", "content"]

  connect() {
    // Bulk modal controller connected
  }

  // モーダルを開く
  async open(event) {
    event.preventDefault()
    const url = event.currentTarget.href

    try {
      const response = await ErrorHandler.fetchWithTimeout(url, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.csrfToken
        }
      })

      if (!response.ok) {
        const errorMessage = ErrorHandler.handleFetchError(response, 'モーダルの読み込み')
        ErrorHandler.showUserMessage(errorMessage)
        return
      }

      const html = await response.text()
      this.contentTarget.innerHTML = html
      this.containerTarget.style.display = 'block'

      // フォーム送信イベントをハンドリング
      this.setupFormSubmit()

      // 閉じるボタンの処理
      this.setupCloseButton()
    } catch (error) {
      const errorMessage = ErrorHandler.handleFetchError(error, 'モーダルの読み込み')
      ErrorHandler.showUserMessage(errorMessage)
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

    // remote="true"が設定されている場合のみAjax処理
    const isRemote = form.getAttribute('data-remote') === 'true'
    if (isRemote) {
      // Ajaxフォーム送信を使用
      form.addEventListener('submit', (e) => {
        e.preventDefault()
        // バリデーションチェック
        if (!this.validateApprovalForm(form)) {
          return
        }
        this.submitForm(form)
      })
    } else {
      // local: true のフォームにもバリデーションを追加
      this.setupApprovalValidation(form)
    }
  }

  // フォーム送信（Ajaxの場合）
  async submitForm(form) {
    const formData = new FormData(form)

    try {
      const response = await ErrorHandler.fetchWithTimeout(form.action, {
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
      const errorMessage = ErrorHandler.handleFetchError(error, 'フォームの送信')
      ErrorHandler.showUserMessage(errorMessage)
    }
  }

  // 成功時の処理
  handleSuccess(form) {
    // 確認ダイアログが必要な場合
    if (form.dataset.confirm === 'true') {
      const message = form.dataset.confirmMessage || '変更内容を送信してよろしいですか？'
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

  // バリデーションチェック（Ajax送信時）
  validateApprovalForm(form) {
    const errorArea = form.querySelector('#validation-errors')

    // エラーメッセージをクリア
    if (errorArea) {
      errorArea.style.display = 'none'
      errorArea.textContent = ''
    }

    // チェックされた項目を取得
    const checkboxes = form.querySelectorAll('input[type="checkbox"][name*="[selected]"]:checked')

    if (checkboxes.length === 0) {
      this.showValidationError(errorArea, '変更する項目にチェックを入れてください')
      return false
    }

    // チェックされた項目の承認/否認が選択されているかを確認
    let hasError = false
    let errorFieldName = 'requests' // デフォルトは残業申請と勤怠変更承認用

    // 月次承認の場合は 'approvals' を使用
    if (form.action.includes('monthly_approvals')) {
      errorFieldName = 'approvals'
    }

    checkboxes.forEach(checkbox => {
      const idMatch = checkbox.name.match(/(?:requests|approvals)\[(\d+)\]/)
      if (!idMatch) return

      const recordId = idMatch[1]
      const statusSelect = form.querySelector(`select[name="${errorFieldName}[${recordId}][status]"]`)

      if (statusSelect && statusSelect.value === 'pending') {
        hasError = true
      }
    })

    if (hasError) {
      this.showValidationError(errorArea, 'チェックした項目の承認/否認を選択してください')
      return false
    }

    return true
  }

  // 承認フォームのバリデーション
  setupApprovalValidation(form) {
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
      let errorFieldName = 'requests' // デフォルトは残業申請と勤怠変更承認用

      // 月次承認の場合は 'approvals' を使用
      if (form.action.includes('monthly_approvals')) {
        errorFieldName = 'approvals'
      }

      checkboxes.forEach(checkbox => {
        const idMatch = checkbox.name.match(/(?:requests|approvals)\[(\d+)\]/)
        if (!idMatch) return

        const recordId = idMatch[1]
        const statusSelect = form.querySelector(`select[name="${errorFieldName}[${recordId}][status]"]`)

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
