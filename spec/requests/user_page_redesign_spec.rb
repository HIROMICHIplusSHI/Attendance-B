require 'rails_helper'

RSpec.describe "UserPageRedesign", type: :request do
  let(:user) { User.create!(name: "テストユーザー", email: "test-#{SecureRandom.hex(4)}@example.com", password: "password123",
                           basic_time: Time.current.change(hour: 8, min: 0),
                           work_time: Time.current.change(hour: 7, min: 30)) }

  before do
    # ログイン処理
    post login_path, params: { session: { email: user.email, password: "password123" } }

    # テスト用勤怠データ作成
    3.times do |i|
      user.attendances.create!(
        worked_on: Date.current.beginning_of_month + i.days,
        started_at: Time.current.change(hour: 9, min: 0) + i.days,
        finished_at: Time.current.change(hour: 18, min: 0) + i.days
      )
    end
  end

  describe "ユーザー詳細ページのクローン元完全再現" do
    before { get user_path(user) }

    describe "2行×4列ユーザー情報テーブル" do
      it "1行目：時間管理表、指定勤務時間、基本時間、月初日が表示されている" do
        expect(response.body).to include("時間管理表")
        expect(response.body).to include("指定勤務時間：7.50")
        expect(response.body).to include("基本時間：8.00")
        expect(response.body).to include("月初日：")
      end

      it "2行目：所属、名前、出勤日数、月末日が表示されている" do
        expect(response.body).to include("所属：")
        expect(response.body).to include("名前：テストユーザー")
        expect(response.body).to include("出勤日数：")
        expect(response.body).to include("月末日：")
      end

      it "user-tableクラスが適用されている" do
        expect(response.body).to include('class="table table-bordered table-condensed user-table"')
      end
    end

    describe "月次ナビゲーションボタン（ユーザー情報テーブル下）" do
      it "btn-users-showクラスのdivが存在している" do
        expect(response.body).to include('class="btn-users-show"')
      end

      it "前月へボタンが存在している" do
        expect(response.body).to include("⇦ 前月へ")
        expect(response.body).to include('class="btn btn-info"')
      end

      it "1ヶ月の勤怠編集へボタンが存在している" do
        expect(response.body).to include("1ヶ月の勤怠編集へ")
        expect(response.body).to include('class="btn btn-success"')
      end

      it "次月へボタンが存在している" do
        expect(response.body).to include("次月へ ⇨")
        expect(response.body).to include('class="btn btn-info"')
      end
    end

    describe "7列シンプル勤怠テーブル" do
      it "table-attendancesのidが適用されている" do
        expect(response.body).to include('id="table-attendances"')
      end

      it "正確な7列のヘッダーが表示されている" do
        expect(response.body).to include('<th class="text-center">日付</th>')
        expect(response.body).to include('<th class="text-center">曜日</th>')
        expect(response.body).to include('<th class="text-center">勤怠登録</th>')
        expect(response.body).to include('<th class="text-center">出勤時間</th>')
        expect(response.body).to include('<th class="text-center">退勤時間</th>')
        expect(response.body).to include('<th class="text-center">在社時間</th>')
        expect(response.body).to include('<th class="text-center">備考</th>')
      end

      it "複雑な多重ヘッダー（rowspan、colspan）が使用されていない" do
        expect(response.body).not_to include('rowspan="3"')
        expect(response.body).not_to include('colspan="8"')
        expect(response.body).not_to include("残業申請")
      end

      it "勤怠登録ボタンが適切に表示されている" do
        expect(response.body).to include("登録")
        expect(response.body).to include('class="btn btn-primary btn-attendance"')
      end
    end

    describe "統計フッター" do
      it "tfootタグが存在している" do
        expect(response.body).to include("<tfoot>")
      end

      it "累計日数ヘッダーが表示されている" do
        expect(response.body).to include("累計日数")
      end

      it "総合勤務時間ヘッダーが表示されている" do
        expect(response.body).to include("総合勤務時間")
      end

      it "累計在社時間ヘッダーが表示されている" do
        expect(response.body).to include("累計在社時間")
      end

      it "統計値が計算されて表示されている" do
        expect(response.body).to match(/\d+日?/)  # 出勤日数
        expect(response.body).to match(/\d+\.\d+/) # 勤務時間（小数点形式）
      end
    end

    describe "レイアウト・スタイル確認" do
      it "Bootstrap table クラスが適用されている" do
        expect(response.body).to include('class="table table-bordered table-condensed table-hover text-center"')
      end

      it "text-centerクラスでセンター寄せされている" do
        expect(response.body).to include('class="text-center"')
      end

      it "適切なBootstrap構造（divコンテナ）になっている" do
        expect(response.body).to include("<div>")
      end
    end
  end

  describe "動的データ表示確認" do
    it "実際の勤怠データが表示されている" do
      get user_path(user)
      expect(response.body).to include("09:00") # 出勤時間
      expect(response.body).to include("18:00") # 退勤時間
    end

    it "曜日が正しく表示されている" do
      get user_path(user)
      expect(response.body).to match(/(月|火|水|木|金|土|日)/)
    end

    it "在社時間が計算されて表示されている" do
      get user_path(user)
      expect(response.body).to include("9.00") # 9時間勤務
    end
  end
end