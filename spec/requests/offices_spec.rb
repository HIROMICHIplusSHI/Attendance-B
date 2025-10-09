require 'rails_helper'

RSpec.describe "Offices", type: :request do
  let(:admin_user) do
    create(:user, role: :admin, employee_number: 'A001')
  end

  let(:general_user) do
    create(:user,
           role: :employee,
           employee_number: 'E001',
           basic_time: Time.zone.parse('2025-01-01 08:00'),
           work_time: Time.zone.parse('2025-01-01 08:00'))
  end

  describe "GET /offices" do
    context "管理者でログイン時" do
      before do
        post login_path, params: { session: { email: admin_user.email, password: 'password' } }
      end

      it "HTTPステータス200を返すこと" do
        get offices_path
        expect(response).to have_http_status(:success)
      end

      it "拠点一覧が表示されること" do
        create(:office, office_number: 1, name: '東京本社')
        create(:office, office_number: 2, name: '大阪支社')
        get offices_path
        expect(response.body).to include('東京本社')
        expect(response.body).to include('大阪支社')
      end
    end

    context "一般ユーザーでログイン時" do
      before do
        post login_path, params: { session: { email: general_user.email, password: 'password' } }
      end

      it "ルートパスにリダイレクトすること" do
        get offices_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "未ログイン時" do
      it "ログインページにリダイレクトすること" do
        get offices_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /offices/new" do
    before do
      post login_path, params: { session: { email: admin_user.email, password: 'password' } }
    end

    it "HTTPステータス200を返すこと" do
      get new_office_path
      expect(response).to have_http_status(:success)
    end

    it "次の拠点番号が表示されること" do
      create(:office, office_number: 1)
      create(:office, office_number: 2)
      get new_office_path
      expect(response.body).to include('3')
    end
  end

  describe "POST /offices" do
    before do
      post login_path, params: { session: { email: admin_user.email, password: 'password' } }
    end

    context "有効なパラメータの場合" do
      it "拠点が作成されること" do
        expect do
          post offices_path, params: { office: { name: '福岡支社', attendance_type: '出勤' } }
        end.to change(Office, :count).by(1)
      end

      it "拠点一覧にリダイレクトすること" do
        post offices_path, params: { office: { name: '福岡支社', attendance_type: '出勤' } }
        expect(response).to redirect_to(offices_path)
      end

      it "拠点番号が自動採番されること" do
        create(:office, office_number: 5)
        post offices_path, params: { office: { name: '福岡支社', attendance_type: '出勤' } }
        expect(Office.last.office_number).to eq(6)
      end

      it "最初の拠点番号は1であること" do
        post offices_path, params: { office: { name: '東京本社', attendance_type: '出勤' } }
        expect(Office.last.office_number).to eq(1)
      end
    end

    context "無効なパラメータの場合" do
      it "拠点が作成されないこと" do
        expect do
          post offices_path, params: { office: { name: '', attendance_type: '出勤' } }
        end.not_to change(Office, :count)
      end
    end
  end

  describe "GET /offices/:id/edit" do
    let(:office) { create(:office) }

    before do
      post login_path, params: { session: { email: admin_user.email, password: 'password' } }
    end

    it "HTTPステータス200を返すこと" do
      get edit_office_path(office)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /offices/:id" do
    let(:office) { create(:office, name: '東京本社') }

    before do
      post login_path, params: { session: { email: admin_user.email, password: 'password' } }
    end

    context "有効なパラメータの場合" do
      it "拠点情報が更新されること" do
        patch office_path(office), params: { office: { name: '東京支社' } }
        office.reload
        expect(office.name).to eq('東京支社')
      end

      it "拠点一覧にリダイレクトすること" do
        patch office_path(office), params: { office: { name: '東京支社' } }
        expect(response).to redirect_to(offices_path)
      end
    end
  end

  describe "DELETE /offices/:id" do
    let!(:office) { create(:office) }

    before do
      post login_path, params: { session: { email: admin_user.email, password: 'password' } }
    end

    it "拠点が削除されること" do
      expect do
        delete office_path(office)
      end.to change(Office, :count).by(-1)
    end

    it "拠点一覧にリダイレクトすること" do
      delete office_path(office)
      expect(response).to redirect_to(offices_path)
    end
  end
end
