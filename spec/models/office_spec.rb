require 'rails_helper'

RSpec.describe Office, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      office = build(:office)
      expect(office).to be_valid
    end

    describe 'office_number' do
      it '必須であること' do
        office = build(:office, office_number: nil)
        office.valid?
        expect(office.errors[:office_number]).to include('を入力してください')
      end

      it '一意であること' do
        create(:office, office_number: 1)
        office = build(:office, office_number: 1)
        office.valid?
        expect(office.errors[:office_number]).to include('はすでに存在します')
      end
    end

    describe 'name' do
      it '必須であること' do
        office = build(:office, name: nil)
        office.valid?
        expect(office.errors[:name]).to include('を入力してください')
      end

      it '50文字以内であること' do
        office = build(:office, name: 'a' * 51)
        office.valid?
        expect(office.errors[:name]).to include('は50文字以内で入力してください')
      end

      it '50文字の場合は有効であること' do
        office = build(:office, name: 'a' * 50)
        expect(office).to be_valid
      end
    end

    describe 'attendance_type' do
      it '必須であること' do
        office = build(:office, attendance_type: nil)
        office.valid?
        expect(office.errors[:attendance_type]).to include('を入力してください')
      end
    end
  end
end
