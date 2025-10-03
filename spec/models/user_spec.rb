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

  describe '組織階層のアソシエーション' do
    describe 'belongs_to :manager' do
      it 'managerとのアソシエーションが正しく設定されていること' do
        expect(User.reflect_on_association(:manager).macro).to eq :belongs_to
        expect(User.reflect_on_association(:manager).options[:class_name]).to eq 'User'
        expect(User.reflect_on_association(:manager).options[:optional]).to be true
      end
    end

    describe 'has_many :subordinates' do
      it 'subordinatesとのアソシエーションが正しく設定されていること' do
        expect(User.reflect_on_association(:subordinates).macro).to eq :has_many
        expect(User.reflect_on_association(:subordinates).options[:class_name]).to eq 'User'
        expect(User.reflect_on_association(:subordinates).options[:foreign_key]).to eq :manager_id
      end
    end

    describe '#manager?' do
      context '部下がいる場合' do
        let(:manager) { User.create(name: "上長", email: "manager@example.com", password: "password") }
        let!(:subordinate) { User.create(name: "部下", email: "subordinate@example.com", password: "password", manager: manager) }

        it 'trueを返すこと' do
          expect(manager.manager?).to be true
        end
      end

      context '部下がいない場合' do
        let(:user) { User.create(name: "一般", email: "general@example.com", password: "password") }

        it 'falseを返すこと' do
          expect(user.manager?).to be false
        end
      end
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
