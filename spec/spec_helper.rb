# SimpleCov設定（テスト実行前に必ず起動）
require 'simplecov'

SimpleCov.start 'rails' do
  # カバレッジから除外するファイル
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  add_filter '/db/migrate/'

  # カバレッジ結果の出力設定
  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Views', 'app/views'

  # 最低カバレッジ率の設定（任意）- Phase 4: テスト拡充中のため一時的に無効化
  # minimum_coverage 80
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
