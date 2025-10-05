// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import ModalController from "controllers/modal_controller"

// Turboをグローバルに露出
window.Turbo = Turbo;

// Stimulusアプリケーションを初期化
const application = Application.start()
application.register("modal", ModalController)
window.Stimulus = application

/**
 * バニラJavaScript ドロップダウンメニュー実装
 * Bootstrap 3のCSSクラスと互換性のあるドロップダウン機能
 * jQuery不要の現代的な実装
 */

// Turbo対応のドロップダウン初期化関数
function initializeDropdowns() {
  console.log('ドロップダウンJavaScript初期化開始');

  // ドロップダウントグル要素を取得
  const dropdownToggles = document.querySelectorAll('.dropdown-toggle');
  console.log('見つかったドロップダウン数:', dropdownToggles.length);

  // 各ドロップダウントグルにイベントリスナーを設定
  dropdownToggles.forEach(function(toggle, index) {
    console.log('ドロップダウン', index + 1, 'に設定中');

    // 既存のリスナーを削除してから新しいリスナーを追加
    toggle.removeEventListener('click', handleDropdownClick);
    toggle.addEventListener('click', handleDropdownClick);
  });

  console.log('ドロップダウンJavaScript初期化完了');
}

// ドロップダウンクリックハンドラー
function handleDropdownClick(event) {
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
}

// 全てのドロップダウンを閉じる関数
function closeAllDropdowns() {
  const openDropdowns = document.querySelectorAll('.dropdown.open');
  openDropdowns.forEach(function(dropdown) {
    dropdown.classList.remove('open');
  });
}

// ドキュメント全体のクリックイベント（ドロップダウン外クリックで閉じる）
function handleDocumentClick(event) {
  // クリック要素がドロップダウン内でない場合
  if (!event.target.closest('.dropdown')) {
    closeAllDropdowns();
  }
}

// Turboイベントでの初期化
document.addEventListener('turbo:load', function() {
  initializeDropdowns();

  // ドキュメントクリックイベントを設定（重複を避けるため一度削除）
  document.removeEventListener('click', handleDocumentClick);
  document.addEventListener('click', handleDocumentClick);
});

// 初回読み込み時の初期化（Turboが無効な場合の備え）
document.addEventListener('DOMContentLoaded', function() {
  initializeDropdowns();

  // ドキュメントクリックイベントを設定
  document.removeEventListener('click', handleDocumentClick);
  document.addEventListener('click', handleDocumentClick);
});