require 'rails_helper'

RSpec.describe SessionsHelper, type: :helper do
  let(:user) { User.create!(name: "テスト太郎", email: "test@example.com", password: "password") }

  describe 'セッション管理' do
    describe '#log_in' do
      it 'ユーザーをログインできること' do
        log_in(user)
        expect(session[:user_id]).to eq(user.id)
      end
    end

    describe '#current_user' do
      context 'セッションにユーザーIDがある場合' do
        it '正しいユーザーを返すこと' do
          log_in(user)
          expect(current_user).to eq(user)
        end
      end

      context 'セッションにユーザーIDがない場合' do
        it 'nilを返すこと' do
          expect(current_user).to be_nil
        end
      end
    end

    describe '#logged_in?' do
      it 'ログイン済みの場合trueを返すこと' do
        log_in(user)
        expect(logged_in?).to be true
      end

      it '未ログインの場合falseを返すこと' do
        expect(logged_in?).to be false
      end
    end

    describe '#log_out' do
      it 'セッションをクリアできること' do
        log_in(user)
        log_out
        expect(current_user).to be_nil
        expect(logged_in?).to be false
      end
    end

    describe '#current_user?' do
      it 'ログイン中ユーザーと同じ場合trueを返すこと' do
        log_in(user)
        expect(current_user?(user)).to be true
      end

      it 'ログイン中ユーザーと異なる場合falseを返すこと' do
        other_user = User.create!(name: "他のユーザー", email: "other@example.com", password: "password")
        log_in(user)
        expect(current_user?(other_user)).to be false
      end

      it '未ログインの場合falseを返すこと' do
        expect(current_user?(user)).to be false
      end
    end
  end

  describe 'リダイレクト管理' do
    describe '#store_location' do
      it 'リクエストされたURLを保存できること' do
        allow(request).to receive(:original_url).and_return("http://example.com/test")
        allow(request).to receive(:get?).and_return(true)
        store_location
        expect(session[:forwarding_url]).to eq("http://example.com/test")
      end
    end

    # 注意: redirect_back_orメソッドのテストはコントローラーテストで実装予定
    # ヘルパーテストではredirect_toが利用できないため
  end
end
