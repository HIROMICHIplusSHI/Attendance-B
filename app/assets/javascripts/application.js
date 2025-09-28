//= require turbo-rails

/**
 * バニラJavaScript ドロップダウンメニュー実装
 * Bootstrap 3のCSSクラスと互換性のあるドロップダウン機能
 * jQuery不要の現代的な実装
 */

// ドキュメント読み込み完了後に実行
document.addEventListener('DOMContentLoaded', function() {
  console.log('ドロップダウンJavaScript初期化開始');

  // ドロップダウントグル要素を取得
  const dropdownToggles = document.querySelectorAll('.dropdown-toggle');
  console.log('見つかったドロップダウン数:', dropdownToggles.length);

  // 各ドロップダウントグルにイベントリスナーを設定
  dropdownToggles.forEach(function(toggle, index) {
    console.log('ドロップダウン', index + 1, 'に設定中');

    toggle.addEventListener('click', function(event) {
      event.preventDefault();
      console.log('ドロップダウンがクリックされました');

      const dropdown = this.parentElement;
      const isCurrentlyOpen = dropdown.classList.contains('open');

      // 全てのドロップダウンを閉じる
      closeAllDropdowns();

      // 現在のドロップダウンが閉じていた場合は開く
      if (!isCurrentlyOpen) {
        dropdown.classList.add('open');
        console.log('ドロップダウンを開きました');
      } else {
        console.log('ドロップダウンを閉じました');
      }
    });
  });

  // ドキュメント全体のクリックイベント（ドロップダウン外クリックで閉じる）
  document.addEventListener('click', function(event) {
    // クリック要素がドロップダウン内でない場合
    if (!event.target.closest('.dropdown')) {
      closeAllDropdowns();
    }
  });

  // 全てのドロップダウンを閉じる関数
  function closeAllDropdowns() {
    const openDropdowns = document.querySelectorAll('.dropdown.open');
    openDropdowns.forEach(function(dropdown) {
      dropdown.classList.remove('open');
    });
  }

  console.log('ドロップダウンJavaScript初期化完了');
});