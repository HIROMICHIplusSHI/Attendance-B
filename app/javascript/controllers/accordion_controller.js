import { Controller } from "@hotwired/stimulus"
import { ErrorHandler } from "../utils/error_handler"

// Connects to data-controller="accordion"
export default class extends Controller {
  static targets = ["content"]
  static values = {
    url: String,
    open: { type: Boolean, default: false }
  }

  connect() {
    // Accordion controller connected
    this.initialFormData = null
  }

  async toggle(event) {
    event.preventDefault()

    const content = this.contentTarget

    // If closing, just hide
    if (this.openValue) {
      content.style.display = "none"
      content.innerHTML = ""
      this.openValue = false
      this.initialFormData = null
      return
    }

    // If opening, load content via Ajax
    try {
      const response = await ErrorHandler.fetchWithTimeout(this.urlValue, {
        headers: {
          "X-Requested-With": "XMLHttpRequest",
          "Accept": "text/html"
        }
      })

      if (response.ok) {
        const html = await response.text()
        content.innerHTML = html
        content.style.display = "block"
        this.openValue = true

        // Save initial form state after loading
        this.saveFormState()

        // Attach submit handler to form
        this.attachSubmitHandler()
      } else {
        const errorMessage = ErrorHandler.handleFetchError(response, '編集フォームの読み込み')
        ErrorHandler.showUserMessage(errorMessage)
      }
    } catch (error) {
      const errorMessage = ErrorHandler.handleFetchError(error, '編集フォームの読み込み')
      ErrorHandler.showUserMessage(errorMessage)
    }
  }

  attachSubmitHandler() {
    const form = this.contentTarget.querySelector('form')
    if (form) {
      form.addEventListener('submit', async (event) => {
        event.preventDefault()

        if (this.hasFormChanged()) {
          if (!confirm('ユーザー情報を更新してもよろしいですか？')) {
            return
          }
        }

        // Submit form via Ajax
        const formData = new FormData(form)
        const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

        try {
          const response = await ErrorHandler.fetchWithTimeout(form.action, {
            method: form.method,
            body: formData,
            headers: {
              'X-CSRF-Token': csrfToken,
              'Accept': 'application/json'
            }
          })

          const data = await response.json()

          if (data.status === 'success') {
            // Success: reload the page
            window.location.href = data.redirect_url
          } else {
            // Error: show errors
            const fieldNames = {
              'name': '名前',
              'email': 'メールアドレス',
              'department': '所属',
              'employee_number': '社員番号',
              'role': '役割',
              'password': 'パスワード',
              'password_confirmation': 'パスワード確認',
              'basic_time': '基本時間',
              'work_time': '指定勤務時間',
              'scheduled_start_time': '指定勤務開始時間',
              'scheduled_end_time': '指定勤務終了時間'
            }

            const errorMessage = ErrorHandler.formatValidationErrors(data.errors, fieldNames)
            alert('入力エラー:\n\n' + errorMessage)
          }
        } catch (error) {
          const errorMessage = ErrorHandler.handleFetchError(error, 'フォームの送信')
          ErrorHandler.showUserMessage(errorMessage)
        }
      })
    }
  }

  saveFormState() {
    const form = this.contentTarget.querySelector('form')
    if (form) {
      // Convert FormData to object for easier comparison
      this.initialFormData = {}

      // Get all form inputs
      const inputs = form.querySelectorAll('input, select, textarea')
      inputs.forEach(input => {
        // Skip disabled fields and file inputs
        if (input.disabled || input.type === 'file') return

        if (input.type === 'checkbox') {
          this.initialFormData[input.name] = input.checked
        } else if (input.type === 'radio') {
          if (input.checked) {
            this.initialFormData[input.name] = input.value
          }
        } else {
          this.initialFormData[input.name] = input.value || ''
        }
      })
    }
  }

  hasFormChanged() {
    const form = this.contentTarget.querySelector('form')
    if (!form || !this.initialFormData) return false

    const inputs = form.querySelectorAll('input, select, textarea')

    for (let input of inputs) {
      // Skip disabled fields and file inputs
      if (input.disabled || input.type === 'file') continue

      let currentValue
      let initialValue = this.initialFormData[input.name]

      if (input.type === 'checkbox') {
        currentValue = input.checked
      } else if (input.type === 'radio') {
        if (input.checked) {
          currentValue = input.value
        } else {
          continue
        }
      } else {
        currentValue = input.value || ''
      }

      if (currentValue !== initialValue) {
        return true
      }
    }

    return false
  }

  closeWithConfirm(event) {
    event.preventDefault()

    if (this.hasFormChanged()) {
      if (!confirm('編集内容が保存されていません。破棄してもよろしいですか？')) {
        return
      }
    }

    this.close()
  }

  close() {
    this.contentTarget.style.display = "none"
    this.contentTarget.innerHTML = ""
    this.openValue = false
    this.initialFormData = null
  }
}
