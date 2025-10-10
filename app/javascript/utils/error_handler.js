/**
 * 共通エラーハンドリングユーティリティ
 *
 * JavaScriptでのエラー処理を統一し、ユーザーフレンドリーなメッセージを提供します
 */

export class ErrorHandler {
  /**
   * Fetch APIのエラーを処理
   * @param {Error|Response} error - エラーオブジェクトまたはレスポンス
   * @param {string} context - エラーが発生したコンテキスト（例: 'モーダルの読み込み'）
   * @returns {string} ユーザーに表示するエラーメッセージ
   */
  static handleFetchError(error, context = '処理') {
    let userMessage = `${context}に失敗しました。`
    let logMessage = error

    if (error instanceof TypeError && error.message.includes('Failed to fetch')) {
      // ネットワークエラー
      userMessage = `ネットワークエラーが発生しました。\nインターネット接続を確認してください。`
      logMessage = `Network error in ${context}: ${error.message}`
    } else if (error instanceof Response) {
      // HTTPエラーレスポンス
      const status = error.status

      if (status === 404) {
        userMessage = `${context}：対象が見つかりませんでした。`
      } else if (status === 403) {
        userMessage = `${context}：アクセスが拒否されました。`
      } else if (status === 500) {
        userMessage = `サーバーエラーが発生しました。\n時間をおいて再度お試しください。`
      } else if (status >= 400 && status < 500) {
        userMessage = `${context}に失敗しました。\n入力内容を確認してください。`
      } else if (status >= 500) {
        userMessage = `サーバーエラーが発生しました。\n管理者に連絡してください。`
      }

      logMessage = `HTTP ${status} error in ${context}: ${error.statusText}`
    } else if (error.name === 'AbortError') {
      // タイムアウトエラー
      userMessage = `${context}がタイムアウトしました。\n時間をおいて再度お試しください。`
      logMessage = `Timeout in ${context}`
    } else {
      // その他のエラー
      logMessage = `Error in ${context}: ${error.message || error}`
    }

    // コンソールにエラーログを出力
    console.error(logMessage, error)

    return userMessage
  }

  /**
   * ユーザーにメッセージを表示
   * @param {string} message - 表示するメッセージ
   * @param {string} type - メッセージタイプ ('error', 'success', 'info')
   */
  static showUserMessage(message, type = 'error') {
    // 現在はalertを使用（将来的にはトースト通知に置き換え可能）
    if (type === 'error') {
      alert(message)
    } else {
      alert(message)
    }
  }

  /**
   * Fetch APIを実行（タイムアウト付き）
   * @param {string} url - リクエストURL
   * @param {object} options - fetchオプション
   * @param {number} timeout - タイムアウト時間（ミリ秒、デフォルト30秒）
   * @returns {Promise<Response>} レスポンス
   */
  static async fetchWithTimeout(url, options = {}, timeout = 30000) {
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), timeout)

    try {
      const response = await fetch(url, {
        ...options,
        signal: controller.signal
      })
      clearTimeout(timeoutId)
      return response
    } catch (error) {
      clearTimeout(timeoutId)
      throw error
    }
  }

  /**
   * バリデーションエラーをフォーマット
   * @param {object} errors - Railsから返されたエラーオブジェクト
   * @param {object} fieldNames - フィールド名の日本語マッピング
   * @returns {string} フォーマットされたエラーメッセージ
   */
  static formatValidationErrors(errors, fieldNames = {}) {
    const errorMessages = []

    for (const [field, messages] of Object.entries(errors)) {
      const fieldName = fieldNames[field] || field
      messages.forEach(msg => {
        errorMessages.push(`${fieldName}${msg}`)
      })
    }

    return errorMessages.join('\n')
  }
}
