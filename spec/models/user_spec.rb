require 'rails_helper'

RSpec.describe User, type: :model do
  describe '基本的なバリデーション' do
    let(:user) { User.new(name: "テスト太郎", email: "test@example.com", password: "password") }

    it '有効なユーザーが作成できること' do
      expect(user).to be_valid
    end

    it '名前が必須であること' do
      user.name = ""
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("を入力してください")
    end

    it 'メールアドレスが必須であること' do
      user.email = ""
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("を入力してください")
    end

    it 'パスワードが必須であること' do
      user = User.new(name: "テスト太郎", email: "test@example.com", password: "")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("を入力してください")
    end
  end

  describe 'メールアドレスの重複チェック' do
    it '同じメールアドレスは登録できないこと' do
      User.create(name: "先輩", email: "test@example.com", password: "password")
      user = User.new(name: "後輩", email: "test@example.com", password: "password")

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("はすでに存在します")
    end
  end
end
