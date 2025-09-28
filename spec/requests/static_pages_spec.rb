require 'rails_helper'

RSpec.describe "StaticPages", type: :request do
  describe "GET /" do
    it "ルートパスが正常にアクセスできる" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "タイトルに'勤怠管理アプリ'が含まれる" do
      get root_path
      expect(response.body).to include('勤怠管理アプリ')
    end

    it "ウェルカムページのタイトルが表示される" do
      get root_path
      expect(response.body).to include('勤怠管理システム')
    end

    it "jumbotronクラスが存在する" do
      get root_path
      expect(response.body).to include('jumbotron')
    end

    it "説明文が表示される" do
      get root_path
      expect(response.body).to include('このアプリケーションでは、登録されたユーザーの勤怠情報を閲覧・登録・編集することができます。')
    end

    it "ログインボタンが表示される" do
      get root_path
      expect(response.body).to include('ログイン')
      expect(response.body).to include('btn btn-lg btn-primary')
    end

    it "アカウント作成のリンクが表示される" do
      get root_path
      expect(response.body).to include('アカウント作成はこちら')
    end
  end
end
