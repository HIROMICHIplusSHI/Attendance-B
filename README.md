# Rails 勤怠管理システム（学習用）

Ruby on Rails の基本的な開発フローを学習するための勤怠管理アプリです。

## 📚 ドキュメント

※カリキュラム勤怠 A の部分のみ記載

- **[IMPLEMENTATION_GUIDE.md](./docs/IMPLEMENTATION_GUIDE.md)**:

## 📚 学習内容

- **Rails 基礎** - MVC、ルーティング、ActiveRecord
- **認証機能** - bcrypt によるログイン実装
- **CRUD 操作** - 基本的な Web アプリケーション機能
- **フロントエンド** - Bootstrap + Stimulus.js
- **テスト駆動開発** - RSpec による TDD 実装
- **CI/CD パイプライン** - 自動テスト・デプロイ
- **リファクタリング** - コード品質向上・保守性改善

## 🌐 デモ

**URL**: https://attendance-app-eemp.onrender.com/

**テストアカウント**:

- 管理者: `admin@example.com` / `password`
- 一般ユーザー: `test@example.com` / `password`

## 💻 使用技術

- **Ruby** 3.2.4 / **Rails** 7.1.4
- **MySQL** (開発) / **PostgreSQL** (本番)
- **Bootstrap** 3.4.1 / **Stimulus.js** (Vanilla JavaScript)
- **Docker** / **RSpec** / **GitHub Actions** / **Render**

## 🚀 開発手順

### 1. 基本環境構築

```
Rails新規作成 → Docker設定 → 基本モデル作成
```

### 2. TDD 実装

```
テスト作成 → 機能実装 → リファクタリング
```

- RSpec によるテスト駆動開発を意識した実装

### 3. 認証・勤怠機能

```
Userモデル → 認証システム → 勤怠CRUD
```

### 4. UI 改善・JavaScript

```
Bootstrap導入 → レスポンシブ対応 → Stimulus.js実装
```

- jQuery を使わないモダンな JavaScript
- Stimulus コントローラーによるインタラクティブ機能

### 5. 管理機能・権限制御

```
admin権限 → ユーザー管理 → 検索・一括編集
```

### 6. 承認ワークフロー

```
月次承認 → 勤怠変更申請 → 残業申請 → 承認・却下機能
```

### 7. テスト・品質管理

```
統合テスト → カバレッジ測定 → リグレッションテスト
```

- 568 のテストケースによる品質確保
- SimpleCov によるカバレッジ測定
- Rubocop 準拠のコード品質

### 8. リファクタリング

```
パフォーマンス最適化 → エラーハンドリング → 保守性向上 → テスト拡充
```

- N+1 クエリ削減
- Service Object 導入
- エラーログ充実
- Request Spec ベースのテスト基盤

### 9. CI/CD・本番公開

```
GitHub Actions → 自動テスト → PostgreSQL対応 → Renderデプロイ
```

## 📋 実装機能

### 基本機能

- ユーザー登録・ログイン（bcrypt 認証）
- 出勤・退勤登録（AJAX 対応）
- 勤怠データ表示・統計
- カレンダー表示・月次切り替え

### 管理機能

- 管理者権限による認可制御
- ユーザー検索（部分一致）
- 1 ヶ月勤怠一括編集
- 基本情報モーダル編集（Stimulus.js）
- アコーディオン式ユーザー編集
- ページネーション（20 件/ページ）
- CSV 入出力機能

### 承認ワークフロー

- 月次勤怠承認（上長・管理者）
- 勤怠変更申請・承認
- 残業申請・承認
- 一括承認機能
- 承認履歴表示

### UI/UX

- Stimulus.js によるモーダル管理
  - 基本情報編集モーダル
  - 統合申請モーダル（勤怠変更・残業申請）
  - 一括承認モーダル
- レスポンシブデザイン
- リアルタイムフォームバリデーション
- 変更検知・保存前確認

## 🧪 テスト・品質管理

- **テスト駆動開発**: RSpec による TDD 実装
- **テスト数**: 568 例（Model / Helper / Request / View）
- **テストファイル**: 104 ファイル
- **リグレッションテスト**: CI 環境での自動実行
- **コード品質**: RuboCop 準拠（違反なし）
- **テスト種別**:
  - Model Spec: バリデーション・アソシエーション
  - Helper Spec: ビューヘルパーロジック
  - Request Spec: HTTP リクエスト・レスポンス
  - View Spec: ビューテンプレート

※学習目的のため、基本的なテストパターンを中心に実装
※System Spec は環境依存問題のため削除（Request Spec で代替）

## 🛠️ セットアップ

### 1. クローン

```bash
git clone https://github.com/HIROMICHIplusSHI/Attendance-B.git
cd attendance_app
```

### 2. 環境構築

```bash
docker-compose up -d
docker-compose exec web bundle install
```

### 3. DB 準備

```bash
docker-compose exec web rails db:create
docker-compose exec web rails db:migrate
docker-compose exec web rails db:seed
```

### 4. 起動

```bash
docker-compose exec web rails server -b 0.0.0.0
```

**アクセス**: http://localhost:3000

## 🧪 テスト実行

```bash
# 全テスト実行
docker-compose exec web bundle exec rspec

# 特定のテストグループ実行
docker-compose exec web bundle exec rspec spec/models
docker-compose exec web bundle exec rspec spec/requests

# カバレッジ付きテスト
docker-compose exec web bundle exec rspec
# 結果: coverage/index.html

# コード品質チェック
docker-compose exec web bundle exec rubocop
```

**注意**: System Spec は環境依存問題（Selenium WebDriver API 不整合）のため削除しています。
JavaScript 機能のテストは Request Spec で代替しています。

## 📊 CI/CD パイプライン

GitHub Actions による自動化:

- **自動テスト**: プッシュ時のリグレッションテスト実行
- **品質チェック**: RuboCop + カバレッジ測定
- **自動デプロイ**: Render への継続的デプロイ

**ワークフロー**:

```
Push → RuboCop → RSpec → デプロイ（mainブランチのみ）
```

## 📖 参考・学習範囲

- Rails Tutorial 相当の基礎知識
- TDD 手法による実装練習
- モダンな Web 開発ワークフロー体験
- リファクタリング・保守性向上の実践

### 実装履歴

- **MVP 機能**: feature/1〜21（基本機能実装）
- **承認フロー**: feature/22〜31（Phase 1〜7）
- **追加機能**: feature/32〜38（CSV、ログ表示等）
- **リファクタリング**: refactor/phase1〜4（品質向上・テスト拡充）
- **ドキュメント整備**: refactor/phase5（進行中）

詳細は `docs/IMPLEMENTATION_GUIDE.md` を参照してください。

## 🛠️ トラブルシューティング

開発中に発生した典型的な問題と解決方法を記録しています：

- **Host Authorization エラー**: Rails 7 のホスト制御設定
- **Capybara 設定**: System/Request テストの環境差異対応
- **CSRF 無効化**: テスト環境での認証トークン設定
- **Database Connection**: Docker 環境での DB 接続問題
- **Asset Pipeline**: JavaScript/CSS 読み込み設定
- **Selenium WebDriver**: バージョン不整合と System Spec 削除

詳細な解決手順は [`docs/troubleshooting/system_test_issues.md`](./docs/troubleshooting/system_test_issues.md) を参照してください。

## 🔍 今後の学習課題

- API 開発（RESTful 設計）
- リアルタイム機能（WebSocket）
- パフォーマンス最適化（キャッシュ戦略）
- セキュリティ強化（認証トークン・XSS 対策）

## 🤝 開発体制

このプロジェクトは**Claude Code（AI）との協働開発**で実現しました。
一人では到底実装できない複雑な機能やベストプラクティスの適用において、
AI ペアプログラミングによる学習効果を最大化しています。

**学習用プロジェクト** - Rails 基礎〜実践（TDD・CI/CD・リファクタリング対応）

🤖 **Co-developed with [Claude Code](https://claude.ai/code)**
