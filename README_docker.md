# Docker開発環境セットアップ

## 権限問題解決済みの開発環境

### 1. 開発環境の起動
```bash
# 開発環境用のDocker Compose使用
docker-compose -f docker-compose.dev.yml up --build

# バックグラウンド実行
docker-compose -f docker-compose.dev.yml up -d --build
```

### 2. よく使うコマンド
```bash
# Rails コンソール
docker-compose -f docker-compose.dev.yml exec web bundle exec rails console

# RSpec テスト実行
docker-compose -f docker-compose.dev.yml exec web bundle exec rspec

# RuboCop 実行
docker-compose -f docker-compose.dev.yml exec web bundle exec rubocop

# マイグレーション
docker-compose -f docker-compose.dev.yml exec web bundle exec rails db:migrate

# Gem 追加時の再ビルド
docker-compose -f docker-compose.dev.yml up --build
```

### 3. エイリアス設定（推奨）
```bash
# ~/.bashrc または ~/.zshrc に追加
alias dc-dev="docker-compose -f docker-compose.dev.yml"
alias dc-exec="docker-compose -f docker-compose.dev.yml exec web"
alias rails-c="docker-compose -f docker-compose.dev.yml exec web bundle exec rails console"
alias rspec="docker-compose -f docker-compose.dev.yml exec web bundle exec rspec"
alias rubocop="docker-compose -f docker-compose.dev.yml exec web bundle exec rubocop"
```

### 4. 権限問題の解決
- ✅ ユーザーID/グループIDをホストと一致
- ✅ bundleキャッシュを専用ボリュームに分離
- ✅ 開発環境用の権限設定
- ✅ development gemグループを有効化

### 5. 本番環境
本番環境は従来の `docker-compose.yml` を使用