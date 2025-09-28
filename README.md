# Rails勤怠管理システム（学習用）

Ruby on Railsの基本的な開発フローを学習するための勤怠管理アプリです。

## 📚 学習内容

- **Rails基礎** - MVC、ルーティング、ActiveRecord
- **認証機能** - bcryptによるログイン実装
- **CRUD操作** - 基本的なWebアプリケーション機能
- **フロントエンド** - Bootstrap + Vanilla JavaScript
- **テスト駆動開発** - RSpecによるTDD実装
- **CI/CDパイプライン** - 自動テスト・デプロイ

## 🌐 デモ

**URL**: https://attendance-app-eemp.onrender.com/

**テストアカウント**:
- 管理者: `admin@example.com` / `password`
- 一般ユーザー: `test@example.com` / `password`

## 💻 使用技術

- **Ruby** 3.2.4 / **Rails** 7.1.4
- **MySQL** (開発) / **PostgreSQL** (本番)
- **Bootstrap** 3.4.1 / **Vanilla JavaScript**
- **Docker** / **RSpec** / **GitHub Actions** / **Render**

## 🚀 開発手順

### 1. 基本環境構築
```
Rails新規作成 → Docker設定 → 基本モデル作成
```

### 2. TDD実装
```
テスト作成 → 機能実装 → リファクタリング
```
- RSpecによるテスト駆動開発を意識した実装

### 3. 認証・勤怠機能
```
Userモデル → 認証システム → 勤怠CRUD
```

### 4. UI改善・JavaScript
```
Bootstrap導入 → レスポンシブ対応 → Vanilla JS実装
```
- jQueryを使わないモダンなJavaScript

### 5. 管理機能・権限制御
```
admin権限 → ユーザー管理 → 検索・一括編集
```

### 6. テスト・品質管理
```
統合テスト → カバレッジ測定 → リグレッションテスト
```
- 183のテストケースによる品質確保
- SimpleCovによるカバレッジ測定（86.22%）

### 7. CI/CD・本番公開
```
GitHub Actions → 自動テスト → PostgreSQL対応 → Renderデプロイ
```

## 📋 実装機能

### 基本機能
- ユーザー登録・ログイン（bcrypt認証）
- 出勤・退勤登録（AJAX対応）
- 勤怠データ表示・統計

### 追加機能
- 管理者権限による認可制御
- ユーザー検索（部分一致）
- 1ヶ月勤怠一括編集
- 基本情報モーダル編集（Vanilla JS）
- ページネーション（20件/ページ）

## 🧪 テスト・品質管理

- **テスト駆動開発**: RSpecによるTDD実装
- **テスト数**: 183例（単体・統合・リクエストテスト）
- **カバレッジ**: 86.22%（SimpleCov測定）
- **リグレッションテスト**: CI環境での自動実行
- **コード品質**: RuboCop準拠

※学習目的のため、基本的なテストパターンを中心に実装

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

### 3. DB準備
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

# E2Eテスト（開発時にPlaywright MCPで実行）
# ※本プロジェクトにはE2Eテストファイルは含まれていません

# カバレッジ付きテスト
docker-compose exec web bundle exec rspec
# 結果: coverage/index.html

# コード品質チェック
docker-compose exec web bundle exec rubocop
```

## 📊 CI/CDパイプライン

GitHub Actionsによる自動化:
- **自動テスト**: プッシュ時のリグレッションテスト実行
- **品質チェック**: RuboCop + カバレッジ測定
- **自動デプロイ**: Renderへの継続的デプロイ

## 📖 参考・学習範囲

- Rails Tutorial相当の基礎知識
- TDD手法による実装練習
- モダンなWeb開発ワークフロー体験

## 🛠️ トラブルシューティング

開発中に発生した典型的な問題と解決方法を記録しています：
- **Host Authorization エラー**: Rails 7のホスト制御設定
- **Capybara設定**: System/Requestテストの環境差異対応
- **CSRF無効化**: テスト環境での認証トークン設定
- **Database Connection**: Docker環境でのDB接続問題
- **Asset Pipeline**: JavaScript/CSS読み込み設定

詳細な解決手順は [`docs/troubleshooting/system_test_issues.md`](./docs/troubleshooting/system_test_issues.md) を参照してください。

## 🔍 今後の学習課題

- API開発（RESTful設計）
- リアルタイム機能（WebSocket）
- パフォーマンス最適化
- セキュリティ強化

## 🤝 開発体制

このプロジェクトは**Claude Code（AI）との協働開発**で実現しました。
一人では到底実装できない複雑な機能やベストプラクティスの適用において、
AIペアプログラミングによる学習効果を最大化しています。

---

**学習用プロジェクト** - Rails基礎〜実践（TDD・CI/CD対応）

🤖 **Co-developed with [Claude Code](https://claude.ai/code)**
