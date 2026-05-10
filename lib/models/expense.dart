// lib/models/expense.dart
import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
enum ExpenseCategory {
  @HiveField(0) food,
  @HiveField(1) transport,
  @HiveField(2) shopping,
  @HiveField(3) utilities,
  @HiveField(4) entertainment,
  @HiveField(5) other,
}

@HiveType(typeId: 1)
class Expense extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  late double amount;

  @HiveField(2)
  late ExpenseCategory category;

  @HiveField(3)
  late DateTime date;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  String get categoryName {
    switch (category) {
      case ExpenseCategory.food:          return 'Food';
      case ExpenseCategory.transport:     return 'Transport';
      case ExpenseCategory.shopping:      return 'Shopping';
      case ExpenseCategory.utilities:     return 'Utilities';
      case ExpenseCategory.entertainment: return 'Entertainment';
      case ExpenseCategory.other:         return 'Other';
    }
  }
}