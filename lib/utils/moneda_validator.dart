/// MonedaValidator: Lớp tiện ích kiểm tra tính hợp lệ của dữ liệu đầu vào và tính toán logic nghiệp vụ cho ứng dụng Moneda.
class MonedaValidator {
  MonedaValidator._();

  /// 1. Kiểm tra tính hợp lệ của giao dịch Nhận tiền (Income)
  static String? validateIncome({
    required String? sourceName,
    required double? amount,
    required String? targetJar,
  }) {
    const validJars = ['ALL_SPLIT', 'ALL', 'NEED', 'WANT', 'SAVE'];
    if (targetJar == null || !validJars.contains(targetJar)) {
      return 'Phương thức phân bổ hũ không hợp lệ';
    }

    if (sourceName == null || sourceName.trim().isEmpty) {
      return 'Nguồn thu nhập không được để trống';
    }

    if (sourceName.length > 100) {
      return 'Tên nguồn thu không được vượt quá 100 ký tự';
    }

    if (amount == null || amount <= 0) {
      return 'Số tiền nhận phải lớn hơn 0 VND';
    }

    return null;
  }

  /// 2. Phân bổ số tiền thu nhập vào các hũ theo tỷ lệ hoặc hũ đích được chọn
  static Map<String, double> calculateIncomeAllocation({
    required double amount,
    required String targetJar,
    required int needRatio,
    required int wantRatio,
    required int saveRatio,
  }) {
    if (targetJar == 'ALL_SPLIT' || targetJar == 'ALL') {
      final need = (amount * needRatio / 100).roundToDouble();
      final want = (amount * wantRatio / 100).roundToDouble();
      final save = amount - need - want; // Bảo toàn tuyệt đối tổng 3 hũ == amount
      return {
        'need': need,
        'want': want,
        'save': save,
      };
    } else if (targetJar == 'NEED') {
      return {
        'need': amount,
        'want': 0.0,
        'save': 0.0,
      };
    } else if (targetJar == 'WANT') {
      return {
        'need': 0.0,
        'want': amount,
        'save': 0.0,
      };
    } else if (targetJar == 'SAVE') {
      return {
        'need': 0.0,
        'want': 0.0,
        'save': amount,
      };
    }

    return {
      'need': 0.0,
      'want': 0.0,
      'save': 0.0,
    };
  }

  /// 3. Kiểm tra tính hợp lệ của giao dịch Chi tiền (Expense)
  static String? validateExpense({
    required String? jarType,
    required String? category,
    required double? amount,
    required double currentJarBalance,
    required String? title,
  }) {
    const validJars = ['NEED', 'WANT', 'SAVE'];
    if (jarType == null || !validJars.contains(jarType)) {
      return 'Vui lòng chọn hũ chi tiêu hợp lệ';
    }

    if (category == null || category.trim().isEmpty) {
      return 'Vui lòng chọn hoặc nhập danh mục chi tiêu';
    }

    if (amount == null || amount <= 0) {
      return 'Số tiền thanh toán phải lớn hơn 0 VND';
    }

    if (amount > currentJarBalance) {
      return 'Số dư trong Hũ $jarType không đủ';
    }

    if (title == null || title.trim().isEmpty) {
      return 'Vui lòng nhập nội dung chi tiết';
    }

    return null;
  }

  /// 4. Tự động cân bằng tỷ lệ các thanh trượt 3 hũ để tổng luôn là 100%
  static Map<String, int> autoBalanceSliders({
    required String changedJar,
    required int newValue,
    required int currentNeed,
    required int currentWant,
    required int currentSave,
  }) {
    final val = newValue.clamp(0, 100);
    int need = currentNeed;
    int want = currentWant;
    int save = currentSave;

    if (changedJar == 'NEED') {
      need = val;
      want = currentWant;
      if (val + want > 100) {
        want = 100 - val;
      }
      save = 100 - val - want;
    } else if (changedJar == 'WANT') {
      want = val;
      need = currentNeed;
      if (need + val > 100) {
        need = 100 - val;
      }
      save = 100 - need - val;
    } else if (changedJar == 'SAVE') {
      save = val;
      need = currentNeed;
      if (need + val > 100) {
        need = 100 - val;
      }
      want = 100 - need - val;
    }

    return {
      'need': need,
      'want': want,
      'save': save,
    };
  }

  /// 5. Kiểm tra tính hợp lệ của giao dịch Chuyển tiền nội bộ giữa các hũ
  static String? validateInternalTransfer({
    required String? fromJar,
    required String? toJar,
    required double? amount,
    required double fromJarBalance,
  }) {
    if (fromJar == null || toJar == null || fromJar == toJar) {
      return 'Hũ nhận phải khác hũ nguồn';
    }

    if (amount == null || amount <= 0) {
      return 'Số tiền chuyển phải lớn hơn 0 VND';
    }

    if (amount > fromJarBalance) {
      return 'Số dư hũ nguồn không đủ để chuyển';
    }

    return null;
  }

  /// 6. Kiểm tra tính hợp lệ khi xóa một khoản thu nhập đã phân bổ
  static String? validateDeleteIncome({
    required double allocatedNeed,
    required double allocatedWant,
    required double allocatedSave,
    required double currentNeedBalance,
    required double currentWantBalance,
    required double currentSaveBalance,
  }) {
    if (currentNeedBalance < allocatedNeed ||
        currentWantBalance < allocatedWant ||
        currentSaveBalance < allocatedSave) {
      return 'Không thể xóa khoản thu nhập này vì số tiền trong hũ đã được chi tiêu!';
    }

    return null;
  }

  /// 7.1 Kiểm tra tính hợp lệ khi tạo hoặc cập nhật mục tiêu tiết kiệm
  static String? validateSavingGoal({
    required String? goalName,
    required double? targetAmount,
  }) {
    if (goalName == null || goalName.trim().isEmpty) {
      return 'Tên mục tiêu không được để trống';
    }

    if (targetAmount == null || targetAmount <= 0) {
      return 'Số tiền mục tiêu phải lớn hơn 0 VND';
    }

    return null;
  }

  /// 7.2 Kiểm tra tính hợp lệ khi gửi tiền từ Hũ SAVE vào mục tiêu tiết kiệm
  static String? validateGoalDeposit({
    required Object? goalId,
    required double? amount,
    required double saveJarBalance,
  }) {
    if (goalId == null || (goalId is String && goalId.trim().isEmpty)) {
      return 'Vui lòng chọn mục tiêu tiết kiệm';
    }

    if (amount == null || amount <= 0) {
      return 'Số tiền gửi phải lớn hơn 0 VND';
    }

    if (amount > saveJarBalance) {
      return 'Số dư Hũ SAVE không đủ để gửi vào mục tiêu';
    }

    return null;
  }

  /// 7.3 Kiểm tra tính hợp lệ khi rút tiền từ mục tiêu tiết kiệm về hũ
  static String? validateGoalWithdraw({
    required String? targetJar,
    required double? amount,
    required double goalCurrentAmount,
  }) {
    const validJars = ['NEED', 'WANT', 'SAVE'];
    if (targetJar == null || !validJars.contains(targetJar)) {
      return 'Vui lòng chọn hũ nhận tiền hợp lệ';
    }

    if (amount == null || amount <= 0) {
      return 'Số tiền rút phải lớn hơn 0 VND';
    }

    if (amount > goalCurrentAmount) {
      return 'Số tiền rút vượt quá số dư mục tiêu';
    }

    return null;
  }

  /// 8.1 Kiểm tra hợp lệ trường Họ và tên
  static String? validateFullName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên hiển thị';
    }
    if (fullName.trim().length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  /// 8.2 Kiểm tra hợp lệ trường Tên đăng nhập (User ID)
  static String? validateUsername(String? username) {
    if (username == null || username.trim().isEmpty) {
      return 'Vui lòng nhập tên đăng nhập';
    }
    final trimmed = username.trim();
    if (trimmed.length < 3) {
      return 'Tên đăng nhập cần tối thiểu 3 ký tự';
    }
    final validUsernameRegex = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!validUsernameRegex.hasMatch(trimmed)) {
      return 'Tên đăng nhập chỉ gồm chữ không dấu, số, dấu chấm (.) hoặc gạch dưới (_)';
    }
    return null;
  }

  /// 8.3 Kiểm tra hợp lệ trường Mật khẩu
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (password.length < 6) {
      return 'Mật khẩu cần tối thiểu 6 ký tự (hiện tại: ${password.length}/6 ký tự)';
    }
    return null;
  }

  /// 8.4 Kiểm tra hợp lệ trường Nhập lại mật khẩu
  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Mật khẩu nhập lại chưa khớp';
    }
    if (confirmPassword != password) {
      return 'Mật khẩu nhập lại chưa khớp';
    }
    return null;
  }

  /// 8.5 Kiểm tra tính hợp lệ khi đăng nhập
  static String? validateLogin({
    required String? username,
    required String? password,
  }) {
    final userErr = validateUsername(username);
    if (userErr != null) return userErr;
    final passErr = validatePassword(password);
    if (passErr != null) return passErr;
    return null;
  }

  /// 8.6 Kiểm tra tính hợp lệ khi đăng ký tài khoản
  static String? validateRegister({
    required String? fullName,
    required String? username,
    required String? password,
    required String? confirmPassword,
  }) {
    final nameErr = validateFullName(fullName);
    if (nameErr != null) return nameErr;
    final userErr = validateUsername(username);
    if (userErr != null) return userErr;
    final passErr = validatePassword(password);
    if (passErr != null) return passErr;
    final confirmErr = validateConfirmPassword(password, confirmPassword);
    if (confirmErr != null) return confirmErr;
    return null;
  }
}

