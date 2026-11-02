import 'package:flutter_test/flutter_test.dart';
import 'package:moneda/utils/moneda_validator.dart';

void main() {
  group('MonedaValidator - validateIncome Tests', () {
    test('Ném lỗi khi phương thức phân bổ targetJar không hợp lệ hoặc null', () {
      expect(
        MonedaValidator.validateIncome(
          sourceName: 'Lương tháng 10',
          amount: 15000000,
          targetJar: null,
        ),
        'Phương thức phân bổ hũ không hợp lệ',
      );

      expect(
        MonedaValidator.validateIncome(
          sourceName: 'Lương tháng 10',
          amount: 15000000,
          targetJar: 'INVALID_JAR',
        ),
        'Phương thức phân bổ hũ không hợp lệ',
      );

      expect(
        MonedaValidator.validateIncome(
          sourceName: 'Lương tháng 10',
          amount: 15000000,
          targetJar: '',
        ),
        'Phương thức phân bổ hũ không hợp lệ',
      );
    });

    test('Ném lỗi khi nguồn thu nhập sourceName để trống hoặc chỉ có khoảng trắng', () {
      expect(
        MonedaValidator.validateIncome(
          sourceName: null,
          amount: 5000000,
          targetJar: 'ALL_SPLIT',
        ),
        'Nguồn thu nhập không được để trống',
      );

      expect(
        MonedaValidator.validateIncome(
          sourceName: '',
          amount: 5000000,
          targetJar: 'ALL_SPLIT',
        ),
        'Nguồn thu nhập không được để trống',
      );

      expect(
        MonedaValidator.validateIncome(
          sourceName: '   ',
          amount: 5000000,
          targetJar: 'ALL_SPLIT',
        ),
        'Nguồn thu nhập không được để trống',
      );
    });

    test('Ném lỗi khi tên nguồn thu vượt quá 100 ký tự', () {
      final longName = 'A' * 101;
      expect(
        MonedaValidator.validateIncome(
          sourceName: longName,
          amount: 1000000,
          targetJar: 'NEED',
        ),
        'Tên nguồn thu không được vượt quá 100 ký tự',
      );

      // Đúng 100 ký tự thì hợp lệ
      final maxValidName = 'A' * 100;
      expect(
        MonedaValidator.validateIncome(
          sourceName: maxValidName,
          amount: 1000000,
          targetJar: 'NEED',
        ),
        isNull,
      );
    });

    test('Ném lỗi khi số tiền nhận <= 0 hoặc null', () {
      expect(
        MonedaValidator.validateIncome(
          sourceName: 'Thưởng KPI',
          amount: null,
          targetJar: 'SAVE',
        ),
        'Số tiền nhận phải lớn hơn 0 VND',
      );

      expect(
        MonedaValidator.validateIncome(
          sourceName: 'Thưởng KPI',
          amount: 0,
          targetJar: 'SAVE',
        ),
        'Số tiền nhận phải lớn hơn 0 VND',
      );

      expect(
        MonedaValidator.validateIncome(
          sourceName: 'Thưởng KPI',
          amount: -500000,
          targetJar: 'SAVE',
        ),
        'Số tiền nhận phải lớn hơn 0 VND',
      );
    });

    test('Trả về null khi dữ liệu thu nhập hoàn toàn hợp lệ', () {
      const validJars = ['ALL_SPLIT', 'NEED', 'WANT', 'SAVE'];
      for (final jar in validJars) {
        final result = MonedaValidator.validateIncome(
          sourceName: 'Tiền freelance',
          amount: 2500000,
          targetJar: jar,
        );
        expect(result, isNull, reason: 'Jar $jar hợp lệ');
      }
    });
  });

  group('MonedaValidator - calculateIncomeAllocation Tests', () {
    test('Phân bổ tự động ALL_SPLIT với tỷ lệ chuẩn 50/30/20', () {
      final result = MonedaValidator.calculateIncomeAllocation(
        amount: 10000000,
        targetJar: 'ALL_SPLIT',
        needRatio: 50,
        wantRatio: 30,
        saveRatio: 20,
      );

      expect(result['need'], 5000000.0);
      expect(result['want'], 3000000.0);
      expect(result['save'], 2000000.0);
      expect(result['need']! + result['want']! + result['save']!, 10000000.0);
    });

    test('Bảo toàn tuyệt đối tổng 3 hũ bằng amount ngay cả khi có số lẻ làm tròn', () {
      const amount = 10000001.0;
      final result = MonedaValidator.calculateIncomeAllocation(
        amount: amount,
        targetJar: 'ALL_SPLIT',
        needRatio: 50,
        wantRatio: 30,
        saveRatio: 20,
      );

      // need = (10000001 * 0.5).roundToDouble() = 5000001.0
      // want = (10000001 * 0.3).roundToDouble() = 3000000.0
      // save = 10000001 - 5000001 - 3000000 = 2000000.0
      expect(result['need'], 5000001.0);
      expect(result['want'], 3000000.0);
      expect(result['save'], 2000000.0);
      expect(result['need']! + result['want']! + result['save']!, amount);
    });

    test('Phân bổ 100% vào hũ NEED khi chọn targetJar = NEED', () {
      final result = MonedaValidator.calculateIncomeAllocation(
        amount: 7000000,
        targetJar: 'NEED',
        needRatio: 50,
        wantRatio: 30,
        saveRatio: 20,
      );

      expect(result['need'], 7000000.0);
      expect(result['want'], 0.0);
      expect(result['save'], 0.0);
    });

    test('Phân bổ 100% vào hũ WANT khi chọn targetJar = WANT', () {
      final result = MonedaValidator.calculateIncomeAllocation(
        amount: 4500000,
        targetJar: 'WANT',
        needRatio: 50,
        wantRatio: 30,
        saveRatio: 20,
      );

      expect(result['need'], 0.0);
      expect(result['want'], 4500000.0);
      expect(result['save'], 0.0);
    });

    test('Phân bổ 100% vào hũ SAVE khi chọn targetJar = SAVE', () {
      final result = MonedaValidator.calculateIncomeAllocation(
        amount: 8200000,
        targetJar: 'SAVE',
        needRatio: 50,
        wantRatio: 30,
        saveRatio: 20,
      );

      expect(result['need'], 0.0);
      expect(result['want'], 0.0);
      expect(result['save'], 8200000.0);
    });
  });

  group('MonedaValidator - validateExpense Tests', () {
    test('Ném lỗi khi jarType không hợp lệ', () {
      expect(
        MonedaValidator.validateExpense(
          jarType: null,
          category: 'Ăn uống',
          amount: 50000,
          currentJarBalance: 1000000,
          title: 'Cơm trưa',
        ),
        'Vui lòng chọn hũ chi tiêu hợp lệ',
      );

      expect(
        MonedaValidator.validateExpense(
          jarType: 'ALL_SPLIT',
          category: 'Ăn uống',
          amount: 50000,
          currentJarBalance: 1000000,
          title: 'Cơm trưa',
        ),
        'Vui lòng chọn hũ chi tiêu hợp lệ',
      );
    });

    test('Ném lỗi khi category rỗng hoặc null', () {
      expect(
        MonedaValidator.validateExpense(
          jarType: 'NEED',
          category: null,
          amount: 50000,
          currentJarBalance: 1000000,
          title: 'Cơm trưa',
        ),
        'Vui lòng chọn hoặc nhập danh mục chi tiêu',
      );

      expect(
        MonedaValidator.validateExpense(
          jarType: 'NEED',
          category: '   ',
          amount: 50000,
          currentJarBalance: 1000000,
          title: 'Cơm trưa',
        ),
        'Vui lòng chọn hoặc nhập danh mục chi tiêu',
      );
    });

    test('Ném lỗi khi amount null hoặc <= 0', () {
      expect(
        MonedaValidator.validateExpense(
          jarType: 'NEED',
          category: 'Ăn uống',
          amount: null,
          currentJarBalance: 1000000,
          title: 'Cơm trưa',
        ),
        'Số tiền thanh toán phải lớn hơn 0 VND',
      );

      expect(
        MonedaValidator.validateExpense(
          jarType: 'NEED',
          category: 'Ăn uống',
          amount: 0,
          currentJarBalance: 1000000,
          title: 'Cơm trưa',
        ),
        'Số tiền thanh toán phải lớn hơn 0 VND',
      );

      expect(
        MonedaValidator.validateExpense(
          jarType: 'NEED',
          category: 'Ăn uống',
          amount: -10000,
          currentJarBalance: 1000000,
          title: 'Cơm trưa',
        ),
        'Số tiền thanh toán phải lớn hơn 0 VND',
      );
    });

    test('Chống âm quỹ: Ném lỗi khi amount > currentJarBalance', () {
      expect(
        MonedaValidator.validateExpense(
          jarType: 'NEED',
          category: 'Thuê nhà',
          amount: 3500000,
          currentJarBalance: 3000000,
          title: 'Tiền phòng trọ',
        ),
        'Số dư trong Hũ NEED không đủ',
      );

      expect(
        MonedaValidator.validateExpense(
          jarType: 'WANT',
          category: 'Mua sắm',
          amount: 1500000,
          currentJarBalance: 500000,
          title: 'Mua giày',
        ),
        'Số dư trong Hũ WANT không đủ',
      );
    });

    test('Ném lỗi khi title rỗng hoặc chỉ có khoảng trắng', () {
      expect(
        MonedaValidator.validateExpense(
          jarType: 'NEED',
          category: 'Ăn uống',
          amount: 45000,
          currentJarBalance: 500000,
          title: null,
        ),
        'Vui lòng nhập nội dung chi tiết',
      );

      expect(
        MonedaValidator.validateExpense(
          jarType: 'NEED',
          category: 'Ăn uống',
          amount: 45000,
          currentJarBalance: 500000,
          title: '   ',
        ),
        'Vui lòng nhập nội dung chi tiết',
      );
    });

    test('Trả về null khi thông tin chi tiêu hợp lệ (kể cả khi amount == currentJarBalance)', () {
      expect(
        MonedaValidator.validateExpense(
          jarType: 'NEED',
          category: 'Đi chợ',
          amount: 500000,
          currentJarBalance: 500000, // Chi hết đúng số dư
          title: 'Siêu thị cuối tuần',
        ),
        isNull,
      );

      expect(
        MonedaValidator.validateExpense(
          jarType: 'WANT',
          category: 'Cafe',
          amount: 65000,
          currentJarBalance: 200000,
          title: 'Cafe sáng',
        ),
        isNull,
      );
    });
  });

  group('MonedaValidator - autoBalanceSliders Tests', () {
    test('Thay đổi NEED: Cập nhật NEED, giữ WANT, SAVE nhận phần còn lại', () {
      // current: need=50, want=30, save=20
      // new need: 60 -> want giữ 30 -> save = 100 - 60 - 30 = 10
      final result = MonedaValidator.autoBalanceSliders(
        changedJar: 'NEED',
        newValue: 60,
        currentNeed: 50,
        currentWant: 30,
        currentSave: 20,
      );

      expect(result['need'], 60);
      expect(result['want'], 30);
      expect(result['save'], 10);
      expect(result['need']! + result['want']! + result['save']!, 100);
    });

    test('Thay đổi NEED vượt quá tổng: Tự ép WANT giảm xuống để vừa 100%', () {
      // current: need=50, want=30, save=20
      // new need: 85 -> 85 + 30 = 115 > 100 -> want = 100 - 85 = 15 -> save = 0
      final result = MonedaValidator.autoBalanceSliders(
        changedJar: 'NEED',
        newValue: 85,
        currentNeed: 50,
        currentWant: 30,
        currentSave: 20,
      );

      expect(result['need'], 85);
      expect(result['want'], 15);
      expect(result['save'], 0);
      expect(result['need']! + result['want']! + result['save']!, 100);
    });

    test('Thay đổi WANT: Cập nhật WANT, giữ NEED, SAVE nhận phần còn lại', () {
      // current: need=50, want=30, save=20
      // new want: 40 -> need giữ 50 -> save = 100 - 50 - 40 = 10
      final result = MonedaValidator.autoBalanceSliders(
        changedJar: 'WANT',
        newValue: 40,
        currentNeed: 50,
        currentWant: 30,
        currentSave: 20,
      );

      expect(result['need'], 50);
      expect(result['want'], 40);
      expect(result['save'], 10);
      expect(result['need']! + result['want']! + result['save']!, 100);
    });

    test('Thay đổi WANT tràn ngưỡng: Ép NEED giảm xuống để bảo đảm tổng = 100%', () {
      // current: need=50, want=30, save=20
      // new want: 70 -> 50 + 70 = 120 > 100 -> need = 100 - 70 = 30 -> save = 0
      final result = MonedaValidator.autoBalanceSliders(
        changedJar: 'WANT',
        newValue: 70,
        currentNeed: 50,
        currentWant: 30,
        currentSave: 20,
      );

      expect(result['need'], 30);
      expect(result['want'], 70);
      expect(result['save'], 0);
      expect(result['need']! + result['want']! + result['save']!, 100);
    });

    test('Thay đổi SAVE: Cập nhật SAVE, giữ NEED, WANT nhận phần còn lại', () {
      // current: need=50, want=30, save=20
      // new save: 35 -> need giữ 50 -> want = 100 - 50 - 35 = 15
      final result = MonedaValidator.autoBalanceSliders(
        changedJar: 'SAVE',
        newValue: 35,
        currentNeed: 50,
        currentWant: 30,
        currentSave: 20,
      );

      expect(result['need'], 50);
      expect(result['want'], 15);
      expect(result['save'], 35);
      expect(result['need']! + result['want']! + result['save']!, 100);
    });

    test('Thay đổi SAVE tràn ngưỡng: Ép NEED giảm xuống và WANT = 0', () {
      // current: need=50, want=30, save=20
      // new save: 80 -> need = 100 - 80 = 20 -> want = 0
      final result = MonedaValidator.autoBalanceSliders(
        changedJar: 'SAVE',
        newValue: 80,
        currentNeed: 50,
        currentWant: 30,
        currentSave: 20,
      );

      expect(result['need'], 20);
      expect(result['want'], 0);
      expect(result['save'], 80);
      expect(result['need']! + result['want']! + result['save']!, 100);
    });

    test('Clamp giá trị nhập ngoài khoảng [0, 100]', () {
      final clampedHigh = MonedaValidator.autoBalanceSliders(
        changedJar: 'NEED',
        newValue: 150,
        currentNeed: 50,
        currentWant: 30,
        currentSave: 20,
      );
      expect(clampedHigh['need'], 100);
      expect(clampedHigh['want'], 0);
      expect(clampedHigh['save'], 0);

      final clampedLow = MonedaValidator.autoBalanceSliders(
        changedJar: 'NEED',
        newValue: -20,
        currentNeed: 50,
        currentWant: 30,
        currentSave: 20,
      );
      expect(clampedLow['need'], 0);
      expect(clampedLow['want'], 30);
      expect(clampedLow['save'], 70);
    });
  });

  group('MonedaValidator - validateInternalTransfer Tests', () {
    test('Ném lỗi khi hũ nguồn hoặc hũ nhận null hoặc giống nhau', () {
      expect(
        MonedaValidator.validateInternalTransfer(
          fromJar: null,
          toJar: 'WANT',
          amount: 100000,
          fromJarBalance: 500000,
        ),
        'Hũ nhận phải khác hũ nguồn',
      );

      expect(
        MonedaValidator.validateInternalTransfer(
          fromJar: 'NEED',
          toJar: null,
          amount: 100000,
          fromJarBalance: 500000,
        ),
        'Hũ nhận phải khác hũ nguồn',
      );

      expect(
        MonedaValidator.validateInternalTransfer(
          fromJar: 'NEED',
          toJar: 'NEED',
          amount: 100000,
          fromJarBalance: 500000,
        ),
        'Hũ nhận phải khác hũ nguồn',
      );
    });

    test('Ném lỗi khi số tiền chuyển <= 0 hoặc null', () {
      expect(
        MonedaValidator.validateInternalTransfer(
          fromJar: 'NEED',
          toJar: 'SAVE',
          amount: null,
          fromJarBalance: 500000,
        ),
        'Số tiền chuyển phải lớn hơn 0 VND',
      );

      expect(
        MonedaValidator.validateInternalTransfer(
          fromJar: 'NEED',
          toJar: 'SAVE',
          amount: 0,
          fromJarBalance: 500000,
        ),
        'Số tiền chuyển phải lớn hơn 0 VND',
      );

      expect(
        MonedaValidator.validateInternalTransfer(
          fromJar: 'NEED',
          toJar: 'SAVE',
          amount: -50000,
          fromJarBalance: 500000,
        ),
        'Số tiền chuyển phải lớn hơn 0 VND',
      );
    });

    test('Ném lỗi khi số tiền chuyển vượt quá số dư hũ nguồn', () {
      expect(
        MonedaValidator.validateInternalTransfer(
          fromJar: 'WANT',
          toJar: 'NEED',
          amount: 600000,
          fromJarBalance: 500000,
        ),
        'Số dư hũ nguồn không đủ để chuyển',
      );
    });

    test('Trả về null khi dữ liệu chuyển tiền hợp lệ (kể cả chuyển hết số dư)', () {
      expect(
        MonedaValidator.validateInternalTransfer(
          fromJar: 'WANT',
          toJar: 'SAVE',
          amount: 500000,
          fromJarBalance: 500000,
        ),
        isNull,
      );

      expect(
        MonedaValidator.validateInternalTransfer(
          fromJar: 'NEED',
          toJar: 'WANT',
          amount: 150000,
          fromJarBalance: 500000,
        ),
        isNull,
      );
    });
  });

  group('MonedaValidator - validateDeleteIncome Tests', () {
    test('Ném lỗi khi số dư hũ NEED hiện tại nhỏ hơn số tiền đã phân bổ', () {
      expect(
        MonedaValidator.validateDeleteIncome(
          allocatedNeed: 1000000,
          allocatedWant: 600000,
          allocatedSave: 400000,
          currentNeedBalance: 800000, // Đã tiêu mất 200k
          currentWantBalance: 600000,
          currentSaveBalance: 400000,
        ),
        'Không thể xóa khoản thu nhập này vì số tiền trong hũ đã được chi tiêu!',
      );
    });

    test('Ném lỗi khi số dư hũ WANT hiện tại nhỏ hơn số tiền đã phân bổ', () {
      expect(
        MonedaValidator.validateDeleteIncome(
          allocatedNeed: 1000000,
          allocatedWant: 600000,
          allocatedSave: 400000,
          currentNeedBalance: 1000000,
          currentWantBalance: 500000, // Đã tiêu mất 100k
          currentSaveBalance: 400000,
        ),
        'Không thể xóa khoản thu nhập này vì số tiền trong hũ đã được chi tiêu!',
      );
    });

    test('Ném lỗi khi số dư hũ SAVE hiện tại nhỏ hơn số tiền đã phân bổ', () {
      expect(
        MonedaValidator.validateDeleteIncome(
          allocatedNeed: 1000000,
          allocatedWant: 600000,
          allocatedSave: 400000,
          currentNeedBalance: 1000000,
          currentWantBalance: 600000,
          currentSaveBalance: 300000, // Đã rút bớt
        ),
        'Không thể xóa khoản thu nhập này vì số tiền trong hũ đã được chi tiêu!',
      );
    });

    test('Trả về null khi cả 3 hũ đều có số dư >= số tiền đã phân bổ', () {
      // Trường hợp vừa vặn bằng nhau
      expect(
        MonedaValidator.validateDeleteIncome(
          allocatedNeed: 1000000,
          allocatedWant: 600000,
          allocatedSave: 400000,
          currentNeedBalance: 1000000,
          currentWantBalance: 600000,
          currentSaveBalance: 400000,
        ),
        isNull,
      );

      // Trường hợp số dư dồi dào hơn
      expect(
        MonedaValidator.validateDeleteIncome(
          allocatedNeed: 1000000,
          allocatedWant: 600000,
          allocatedSave: 400000,
          currentNeedBalance: 5000000,
          currentWantBalance: 2000000,
          currentSaveBalance: 3000000,
        ),
        isNull,
      );
    });
  });

  group('MonedaValidator - Saving Goal Tests', () {
    group('validateSavingGoal', () {
      test('Ném lỗi khi tên mục tiêu để trống hoặc null', () {
        expect(
          MonedaValidator.validateSavingGoal(
            goalName: null,
            targetAmount: 10000000,
          ),
          'Tên mục tiêu không được để trống',
        );

        expect(
          MonedaValidator.validateSavingGoal(
            goalName: '   ',
            targetAmount: 10000000,
          ),
          'Tên mục tiêu không được để trống',
        );
      });

      test('Ném lỗi khi targetAmount <= 0 hoặc null', () {
        expect(
          MonedaValidator.validateSavingGoal(
            goalName: 'Mua laptop',
            targetAmount: null,
          ),
          'Số tiền mục tiêu phải lớn hơn 0 VND',
        );

        expect(
          MonedaValidator.validateSavingGoal(
            goalName: 'Mua laptop',
            targetAmount: 0,
          ),
          'Số tiền mục tiêu phải lớn hơn 0 VND',
        );

        expect(
          MonedaValidator.validateSavingGoal(
            goalName: 'Mua laptop',
            targetAmount: -5000000,
          ),
          'Số tiền mục tiêu phải lớn hơn 0 VND',
        );
      });

      test('Trả về null khi thông tin mục tiêu tiết kiệm hợp lệ', () {
        expect(
          MonedaValidator.validateSavingGoal(
            goalName: 'Mua xe máy mới',
            targetAmount: 25000000,
          ),
          isNull,
        );
      });
    });

    group('validateGoalDeposit', () {
      test('Ném lỗi khi goalId để trống hoặc null', () {
        expect(
          MonedaValidator.validateGoalDeposit(
            goalId: null,
            amount: 500000,
            saveJarBalance: 2000000,
          ),
          'Vui lòng chọn mục tiêu tiết kiệm',
        );

        expect(
          MonedaValidator.validateGoalDeposit(
            goalId: '   ',
            amount: 500000,
            saveJarBalance: 2000000,
          ),
          'Vui lòng chọn mục tiêu tiết kiệm',
        );
      });

      test('Ném lỗi khi số tiền nạp <= 0 hoặc null', () {
        expect(
          MonedaValidator.validateGoalDeposit(
            goalId: 'goal-123',
            amount: null,
            saveJarBalance: 2000000,
          ),
          'Số tiền gửi phải lớn hơn 0 VND',
        );

        expect(
          MonedaValidator.validateGoalDeposit(
            goalId: 'goal-123',
            amount: 0,
            saveJarBalance: 2000000,
          ),
          'Số tiền gửi phải lớn hơn 0 VND',
        );

        expect(
          MonedaValidator.validateGoalDeposit(
            goalId: 'goal-123',
            amount: -100000,
            saveJarBalance: 2000000,
          ),
          'Số tiền gửi phải lớn hơn 0 VND',
        );
      });

      test('Ném lỗi khi số tiền gửi vượt quá số dư Hũ SAVE', () {
        expect(
          MonedaValidator.validateGoalDeposit(
            goalId: 'goal-123',
            amount: 2500000,
            saveJarBalance: 2000000,
          ),
          'Số dư Hũ SAVE không đủ để gửi vào mục tiêu',
        );
      });

      test('Trả về null khi số tiền nạp hợp lệ (kể cả nạp hết số dư hũ SAVE)', () {
        expect(
          MonedaValidator.validateGoalDeposit(
            goalId: 'goal-123',
            amount: 2000000,
            saveJarBalance: 2000000,
          ),
          isNull,
        );

        expect(
          MonedaValidator.validateGoalDeposit(
            goalId: 'goal-123',
            amount: 500000,
            saveJarBalance: 2000000,
          ),
          isNull,
        );
      });
    });

    group('validateGoalWithdraw', () {
      test('Ném lỗi khi hũ nhận tiền không hợp lệ hoặc null', () {
        expect(
          MonedaValidator.validateGoalWithdraw(
            targetJar: null,
            amount: 500000,
            goalCurrentAmount: 1000000,
          ),
          'Vui lòng chọn hũ nhận tiền hợp lệ',
        );

        expect(
          MonedaValidator.validateGoalWithdraw(
            targetJar: 'ALL_SPLIT',
            amount: 500000,
            goalCurrentAmount: 1000000,
          ),
          'Vui lòng chọn hũ nhận tiền hợp lệ',
        );
      });

      test('Ném lỗi khi số tiền rút <= 0 hoặc null', () {
        expect(
          MonedaValidator.validateGoalWithdraw(
            targetJar: 'SAVE',
            amount: null,
            goalCurrentAmount: 1000000,
          ),
          'Số tiền rút phải lớn hơn 0 VND',
        );

        expect(
          MonedaValidator.validateGoalWithdraw(
            targetJar: 'SAVE',
            amount: 0,
            goalCurrentAmount: 1000000,
          ),
          'Số tiền rút phải lớn hơn 0 VND',
        );

        expect(
          MonedaValidator.validateGoalWithdraw(
            targetJar: 'SAVE',
            amount: -10000,
            goalCurrentAmount: 1000000,
          ),
          'Số tiền rút phải lớn hơn 0 VND',
        );
      });

      test('Ném lỗi khi số tiền rút vượt quá số dư hiện tại của mục tiêu', () {
        expect(
          MonedaValidator.validateGoalWithdraw(
            targetJar: 'SAVE',
            amount: 1500000,
            goalCurrentAmount: 1000000,
          ),
          'Số tiền rút vượt quá số dư mục tiêu',
        );
      });

      test('Trả về null khi rút tiền hợp lệ (kể cả rút toàn bộ số dư mục tiêu)', () {
        expect(
          MonedaValidator.validateGoalWithdraw(
            targetJar: 'SAVE',
            amount: 1000000,
            goalCurrentAmount: 1000000,
          ),
          isNull,
        );

        expect(
          MonedaValidator.validateGoalWithdraw(
            targetJar: 'NEED',
            amount: 200000,
            goalCurrentAmount: 1000000,
          ),
          isNull,
        );
      });
    });
  });
}

