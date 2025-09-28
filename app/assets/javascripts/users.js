// ユーザー削除モーダルの制御（Vanilla JavaScript）
document.addEventListener('DOMContentLoaded', function() {
  let deleteUserId = null;

  // モーダル表示関数
  function showModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.style.display = 'block';
      modal.classList.add('show');
      modal.setAttribute('aria-hidden', 'false');
      document.body.classList.add('modal-open');

      // 背景オーバーレイを追加
      const backdrop = document.createElement('div');
      backdrop.className = 'modal-backdrop fade show';
      backdrop.id = 'modal-backdrop';
      document.body.appendChild(backdrop);
    }
  }

  // モーダル非表示関数
  function hideModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.style.display = 'none';
      modal.classList.remove('show');
      modal.setAttribute('aria-hidden', 'true');
      document.body.classList.remove('modal-open');

      // 背景オーバーレイを削除
      const backdrop = document.getElementById('modal-backdrop');
      if (backdrop) {
        backdrop.remove();
      }
    }
  }

  // 削除ボタンクリック時のイベント
  document.addEventListener('click', function(e) {
    if (e.target.matches('[data-target="#deleteModal"]')) {
      e.preventDefault();
      const button = e.target;
      deleteUserId = button.getAttribute('data-user-id');
      const userName = button.getAttribute('data-user-name');
      const userEmail = button.getAttribute('data-user-email');

      // モーダル内の情報を更新
      document.getElementById('modalUserName').textContent = userName;
      document.getElementById('modalUserEmail').textContent = userEmail;

      // モーダルを表示
      showModal('deleteModal');
    }
  });

  // モーダル閉じるボタンのイベント
  document.addEventListener('click', function(e) {
    if (e.target.matches('[data-dismiss="modal"]') || e.target.closest('[data-dismiss="modal"]')) {
      hideModal('deleteModal');
    }
  });

  // 背景クリックでモーダルを閉じる
  document.addEventListener('click', function(e) {
    if (e.target.id === 'modal-backdrop') {
      hideModal('deleteModal');
    }
  });

  // Escキーでモーダルを閉じる
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      hideModal('deleteModal');
    }
  });

  // 削除確認ボタンクリック時のイベント
  const confirmDeleteBtn = document.getElementById('confirmDelete');
  if (confirmDeleteBtn) {
    confirmDeleteBtn.addEventListener('click', function() {
      if (deleteUserId) {
        // CSRFトークンを取得
        const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

        // フォームを動的に作成してDELETEリクエストを送信
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = `/users/${deleteUserId}`;
        form.style.display = 'none';

        // _methodフィールドを追加（DELETE用）
        const methodInput = document.createElement('input');
        methodInput.type = 'hidden';
        methodInput.name = '_method';
        methodInput.value = 'DELETE';
        form.appendChild(methodInput);

        // CSRFトークンを追加
        const csrfInput = document.createElement('input');
        csrfInput.type = 'hidden';
        csrfInput.name = 'authenticity_token';
        csrfInput.value = csrfToken;
        form.appendChild(csrfInput);

        // フォームをbodyに追加して送信
        document.body.appendChild(form);
        form.submit();
      }
    });
  }
});