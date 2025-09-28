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

  describe 'remember機能' do
    let(:user) { User.create(name: "テスト太郎", email: "test@example.com", password: "password") }

    describe '#remember' do
      it 'rememberトークンとremember_digestが設定されること' do
        user.remember
        expect(user.remember_token).not_to be_nil
        expect(user.remember_digest).not_to be_nil
      end
    end

    describe '#authenticated?' do
      it '有効なrememberトークンで認証できること' do
        user.remember
        expect(user.authenticated?(user.remember_token)).to be true
      end

      it '無効なrememberトークンで認証できないこと' do
        user.remember
        expect(user.authenticated?('invalid_token')).to be false
      end

      it 'remember_digestがnilの場合はfalseを返すこと' do
        expect(user.authenticated?('any_token')).to be false
      end
    end

    describe '#forget' do
      it 'remember_digestがnilに設定されること' do
        user.remember
        user.forget
        expect(user.remember_digest).to be_nil
      end
    end
  end
end
