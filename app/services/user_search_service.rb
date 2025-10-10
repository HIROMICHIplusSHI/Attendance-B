# frozen_string_literal: true

# ユーザー検索サービス
class UserSearchService
  # @param params [Hash] 検索パラメータ
  # @option params [String] :search 検索キーワード
  # @option params [Integer] :page ページ番号
  # @option params [Integer] :per ページあたりの件数
  def initialize(params = {})
    @search_query = params[:search]
    @page = params[:page]
    @per_page = params[:per] || 20
  end

  # ユーザー検索を実行
  # @return [ActiveRecord::Relation] ページネーション済みのユーザーリスト
  def call
    users = User.all
    users = apply_search(users) if @search_query.present?
    users.page(@page).per(@per_page).order(:name)
  end

  private

  # 検索条件を適用
  # @param relation [ActiveRecord::Relation] ユーザーのリレーション
  # @return [ActiveRecord::Relation] 検索条件適用後のリレーション
  def apply_search(relation)
    relation.where('name LIKE ?', "%#{sanitize_query(@search_query)}%")
  end

  # SQLインジェクション対策：検索クエリのサニタイズ
  # @param query [String] 検索クエリ
  # @return [String] サニタイズ済みクエリ
  def sanitize_query(query)
    # ActiveRecord::Sanitization の where メソッドが自動的にサニタイズするため、
    # ここでは特殊文字のエスケープのみ実施
    query.gsub(/[%_]/) { |char| "\\#{char}" }
  end
end
