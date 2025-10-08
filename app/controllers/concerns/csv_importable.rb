module CsvImportable
  extend ActiveSupport::Concern

  def import_csv
    return redirect_with_file_error unless csv_file_present?

    result = process_csv_import(params[:file].path)
    handle_import_result(result)
  rescue CSV::MalformedCSVError => e
    handle_csv_error(e)
  rescue StandardError => e
    handle_standard_error(e)
  end

  private

  def process_csv_import(file_path)
    success_count = 0
    errors = []

    CSV.foreach(file_path, headers: true) do |row|
      user_data = extract_user_data(row)
      validation_error = validate_csv_row(user_data)

      if validation_error
        errors << validation_error
        next
      end

      user = create_user_from_csv(user_data)
      if user.save
        success_count += 1
      else
        errors << "#{user_data[:employee_number]}: #{user.errors.full_messages.join(', ')}"
      end
    end

    { success_count:, errors: }
  end

  def extract_user_data(row)
    {
      employee_number: row['社員番号'],
      name: row['氏名'],
      email: row['メールアドレス'],
      password: row['パスワード'],
      role: row['役割'],
      manager_employee_number: row['上長社員番号']
    }
  end

  def validate_csv_row(data)
    unless %w[employee manager admin].include?(data[:role])
      return "#{data[:employee_number]}: 役割が不正です" \
             "（employee/manager/adminのいずれかを指定してください）"
    end

    return unless data[:manager_employee_number].present?

    manager = User.find_by(employee_number: data[:manager_employee_number])
    return unless manager.nil?

    "#{data[:employee_number]}: 上長社員番号「#{data[:manager_employee_number]}」が存在しません"
  end

  def create_user_from_csv(data)
    manager = User.find_by(employee_number: data[:manager_employee_number]) if data[:manager_employee_number].present?

    User.new(
      employee_number: data[:employee_number],
      name: data[:name],
      email: data[:email],
      password: data[:password],
      password_confirmation: data[:password],
      role: data[:role],
      manager_id: manager&.id,
      basic_time: Time.zone.parse("08:00"),
      work_time: Time.zone.parse("07:30")
    )
  end

  def handle_import_result(result)
    if result[:errors].any?
      flash[:danger] = result[:errors].join("<br>").html_safe
    else
      flash[:success] = "#{result[:success_count]}件のユーザーを登録しました"
    end
    redirect_to users_path
  end

  def csv_file_present?
    params[:file].present?
  end

  def redirect_with_file_error
    flash[:danger] = "CSVファイルを選択してください"
    redirect_to users_path
  end

  def handle_csv_error(error)
    flash[:danger] = "CSVファイルの形式が不正です: #{error.message}"
    redirect_to users_path
  end

  def handle_standard_error(error)
    flash[:danger] = "エラーが発生しました: #{error.message}"
    redirect_to users_path
  end
end
