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

    describe '#manager? (role-based)' do
      context 'manager roleの場合' do
        let(:manager) do
          User.create!(
            name: "上長",
            email: "manager_role@example.com",
            password: "password",
            role: :manager,
            basic_time: Time.zone.parse("2025-01-01 08:00"),
            work_time: Time.zone.parse("2025-01-01 08:00")
          )
        end

        it 'trueを返すこと' do
          expect(manager.manager?).to be true
        end
      end

      context 'employee roleの場合' do
        let(:user) do
          User.create!(
            name: "一般",
            email: "general_role@example.com",
            password: "password",
            role: :employee,
            basic_time: Time.zone.parse("2025-01-01 08:00"),
            work_time: Time.zone.parse("2025-01-01 08:00")
          )
        end

        it 'falseを返すこと' do
          expect(user.manager?).to be false
        end
      end
    end
  end

  describe 'role enum' do
    describe 'employee role' do
      let(:employee) do
        User.create!(
          name: "一般社員",
          email: "employee@example.com",
          password: "password",
          role: :employee,
          basic_time: Time.zone.parse("2025-01-01 08:00"),
          work_time: Time.zone.parse("2025-01-01 08:00")
        )
      end

      it 'employee?がtrueを返すこと' do
        expect(employee.employee?).to be true
      end

      it 'manager?がfalseを返すこと' do
        expect(employee.manager?).to be false
      end

      it 'admin?がfalseを返すこと' do
        expect(employee.admin?).to be false
      end

      it 'can_approve?がfalseを返すこと' do
        expect(employee.can_approve?).to be false
      end
    end

    describe 'manager role' do
      let(:manager) do
        User.create!(
          name: "上長",
          email: "manager@example.com",
          password: "password",
          role: :manager,
          basic_time: Time.zone.parse("2025-01-01 08:00"),
          work_time: Time.zone.parse("2025-01-01 08:00")
        )
      end

      it 'manager?がtrueを返すこと' do
        expect(manager.manager?).to be true
      end

      it 'employee?がfalseを返すこと' do
        expect(manager.employee?).to be false
      end

      it 'admin?がfalseを返すこと' do
        expect(manager.admin?).to be false
      end

      it 'can_approve?がtrueを返すこと' do
        expect(manager.can_approve?).to be true
      end
    end

    describe 'admin role' do
      let(:admin) do
        User.create!(
          name: "管理者",
          email: "admin@example.com",
          password: "password",
          role: :admin,
          basic_time: Time.zone.parse("2025-01-01 08:00"),
          work_time: Time.zone.parse("2025-01-01 08:00")
        )
      end

      it 'admin?がtrueを返すこと' do
        expect(admin.admin?).to be true
      end

      it 'manager?がfalseを返すこと' do
        expect(admin.manager?).to be false
      end

      it 'employee?がfalseを返すこと' do
        expect(admin.employee?).to be false
      end
    end

    describe 'デフォルト値' do
      let(:user) do
        User.create!(
          name: "デフォルトユーザー",
          email: "default@example.com",
          password: "password",
          basic_time: Time.zone.parse("2025-01-01 08:00"),
          work_time: Time.zone.parse("2025-01-01 08:00")
        )
      end

      it 'デフォルトでemployee roleが設定されること' do
        expect(user.role).to eq('employee')
        expect(user.employee?).to be true
      end
    end
  end

  describe 'employee_number' do
    it '社員番号が一意であること' do
      User.create!(
        name: "社員A",
        email: "employeeA@example.com",
        password: "password",
        employee_number: "100001",
        basic_time: Time.zone.parse("2025-01-01 08:00"),
        work_time: Time.zone.parse("2025-01-01 08:00")
      )

      duplicate_user = User.new(
        name: "社員B",
        email: "employeeB@example.com",
        password: "password",
        employee_number: "100001",
        basic_time: Time.zone.parse("2025-01-01 08:00"),
        work_time: Time.zone.parse("2025-01-01 08:00")
      )

      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:employee_number]).to include("はすでに存在します")
    end

    it '社員番号がnilでも作成できること' do
      user = User.create!(
        name: "社員C",
        email: "employeeC@example.com",
        password: "password",
        basic_time: Time.zone.parse("2025-01-01 08:00"),
        work_time: Time.zone.parse("2025-01-01 08:00")
      )

      expect(user).to be_valid
      expect(user.employee_number).to be_nil
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
