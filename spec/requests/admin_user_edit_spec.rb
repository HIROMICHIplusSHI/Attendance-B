# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "AdminUserEdit", type: :request do
  let(:admin) do
    User.create!(
      name: "管理者",
      email: "admin@example.com",
      password: "password",
      role: :admin,
      basic_time: Time.zone.parse("08:00"),
      work_time: Time.zone.parse("07:30")
    )
  end

  let(:target_user) do
    User.create!(
      name: "対象ユーザー",
      email: "target@example.com",
      password: "password",
      department: "開発部",
      basic_time: Time.zone.parse("08:00"),
      work_time: Time.zone.parse("07:30")
    )
  end

  let(:regular_user) do
    User.create!(
      name: "一般ユーザー",
      email: "regular@example.com",
      password: "password",
      basic_time: Time.zone.parse("08:00"),
      work_time: Time.zone.parse("07:30")
    )
  end

  before do
    post login_path, params: { session: { email: admin.email, password: "password" } }
  end

  describe "GET /users/:id/edit_admin" do
    context "管理者としてログインしている場合" do
      it "HTTPステータス200を返すこと" do
        get edit_admin_user_path(target_user), xhr: true
        expect(response).to have_http_status(:success)
      end

      it "編集フォームを返すこと" do
        get edit_admin_user_path(target_user), xhr: true
        expect(response.body).to include('ユーザー編集')
      end

      it "全ての編集項目が表示されること" do
        get edit_admin_user_path(target_user), xhr: true

        # 基本情報
        expect(response.body).to include('name')
        expect(response.body).to include('email')
        expect(response.body).to include('department')

        # 勤務時間（計算用）
        expect(response.body).to include('basic_time')
        expect(response.body).to include('work_time')

        # 勤務時間（表示用）
        expect(response.body).to include('scheduled_start_time')
        expect(response.body).to include('scheduled_end_time')
      end

      it "カードIDフィールドがdisabledになっていること" do
        get edit_admin_user_path(target_user), xhr: true
        expect(response.body).to include('user[card_id]')
        expect(response.body).to include('disabled')
      end

      it "layout: false でレンダリングされること" do
        get edit_admin_user_path(target_user), xhr: true
        expect(response.body).not_to include('<!DOCTYPE html>')
      end
    end

    context "一般ユーザーの場合" do
      before do
        delete logout_path
        post login_path, params: { session: { email: regular_user.email, password: "password" } }
      end

      it "アクセスが拒否されること" do
        get edit_admin_user_path(target_user)
        expect(response).to redirect_to(root_path)
      end

      it "エラーメッセージが表示されること" do
        get edit_admin_user_path(target_user)
        expect(flash[:danger]).to eq('管理者権限が必要です。')
      end
    end

    context "ログインしていない場合" do
      before { delete logout_path }

      it "ログインページにリダイレクトされること" do
        get edit_admin_user_path(target_user)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "PATCH /users/:id/update_admin" do
    let(:valid_params) do
      {
        user: {
          name: '更新太郎',
          email: 'updated@example.com',
          department: '営業部',
          basic_time: '08:00',
          work_time: '07:30',
          scheduled_start_time: '09:00',
          scheduled_end_time: '18:00'
        }
      }
    end

    context "管理者としてログインしている場合" do
      context "有効なパラメータの場合" do
        it "ユーザー情報を更新すること" do
          patch update_admin_user_path(target_user), params: valid_params

          target_user.reload
          expect(target_user.name).to eq('更新太郎')
          expect(target_user.email).to eq('updated@example.com')
          expect(target_user.department).to eq('営業部')
        end

        it "勤務時間（計算用）を更新すること" do
          patch update_admin_user_path(target_user), params: valid_params

          target_user.reload
          expect(target_user.basic_time.strftime('%H:%M')).to eq('08:00')
          expect(target_user.work_time.strftime('%H:%M')).to eq('07:30')
        end

        it "勤務時間（表示用）を更新すること" do
          patch update_admin_user_path(target_user), params: valid_params

          target_user.reload
          expect(target_user.scheduled_start_time.strftime('%H:%M')).to eq('09:00')
          expect(target_user.scheduled_end_time.strftime('%H:%M')).to eq('18:00')
        end

        it "成功メッセージを表示すること" do
          patch update_admin_user_path(target_user), params: valid_params
          expect(flash[:success]).to include('情報を更新しました')
        end

        it "ユーザー一覧ページにリダイレクトすること" do
          patch update_admin_user_path(target_user), params: valid_params
          expect(response).to redirect_to(users_path)
        end
      end

      context "無効なパラメータの場合" do
        let(:invalid_params) do
          {
            user: {
              email: 'invalid-email'
            }
          }
        end

        it "ユーザー情報を更新しないこと" do
          original_email = target_user.email
          patch update_admin_user_path(target_user), params: invalid_params

          target_user.reload
          expect(target_user.email).to eq(original_email)
        end

        it "編集フォームを再表示すること" do
          patch update_admin_user_path(target_user), params: invalid_params, xhr: true
          expect(response).to have_http_status(:success)
          expect(response.body).to include('ユーザー編集')
        end

        it "layout: false でレンダリングされること" do
          patch update_admin_user_path(target_user), params: invalid_params, xhr: true
          expect(response.body).not_to include('<!DOCTYPE html>')
        end
      end

      context "パスワード変更の場合" do
        let(:password_params) do
          {
            user: {
              password: 'newpassword',
              password_confirmation: 'newpassword'
            }
          }
        end

        it "パスワードを更新すること" do
          patch update_admin_user_path(target_user), params: password_params

          target_user.reload
          expect(target_user.authenticate('newpassword')).to be_truthy
        end
      end

      context "空文字のフィールドがnilに変換される場合" do
        let(:empty_fields_params) do
          {
            user: {
              employee_number: '',
              scheduled_start_time: '',
              scheduled_end_time: ''
            }
          }
        end

        it "employee_numberが空文字の場合nilに変換されること" do
          patch update_admin_user_path(target_user), params: empty_fields_params

          target_user.reload
          expect(target_user.employee_number).to be_nil
        end

        it "scheduled_start_timeが空文字の場合nilに変換されること" do
          patch update_admin_user_path(target_user), params: empty_fields_params

          target_user.reload
          expect(target_user.scheduled_start_time).to be_nil
        end

        it "scheduled_end_timeが空文字の場合nilに変換されること" do
          patch update_admin_user_path(target_user), params: empty_fields_params

          target_user.reload
          expect(target_user.scheduled_end_time).to be_nil
        end
      end

      context "役割変更の場合" do
        it "一般社員から上長に変更できること" do
          target_user.update!(role: :employee)

          patch update_admin_user_path(target_user), params: { user: { role: 'manager' } }

          target_user.reload
          expect(target_user.role).to eq('manager')
        end

        it "上長から一般社員に変更できること" do
          target_user.update!(role: :manager)

          patch update_admin_user_path(target_user), params: { user: { role: 'employee' } }

          target_user.reload
          expect(target_user.role).to eq('employee')
        end

        it "管理者への変更が防止されること" do
          original_role = target_user.role

          patch update_admin_user_path(target_user), params: { user: { role: 'admin' } }

          target_user.reload
          expect(target_user.role).to eq(original_role)
          expect(target_user.role).not_to eq('admin')
        end
      end
    end

    context "一般ユーザーの場合" do
      before do
        delete logout_path
        post login_path, params: { session: { email: regular_user.email, password: "password" } }
      end

      it "アクセスが拒否されること" do
        patch update_admin_user_path(target_user), params: valid_params
        expect(response).to redirect_to(root_path)
      end

      it "ユーザー情報を更新しないこと" do
        original_name = target_user.name
        patch update_admin_user_path(target_user), params: valid_params

        target_user.reload
        expect(target_user.name).to eq(original_name)
      end
    end
  end
end
