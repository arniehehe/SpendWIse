// lib/services/expense_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';

class ExpenseService {
  static const String _boxName = 'expenses';

  static Box<Expense> get _box => Hive.box<Expense>(_boxName);

  // CREATE
  static Future<void> addExpense(Expense expense) async {
    await _box.add(expense);
  }

  // READ ALL
  static List<Expense> getAllExpenses() {
    return _box.values.toList();
  }

  // READ BY CATEGORY
  static List<Expense> getExpensesByCategory(ExpenseCategory category) {
    return _box.values.where((e) => e.category == category).toList();
  }

  // UPDATE
  static Future<void> updateExpense(int key, Expense updated) async {
    await _box.put(key, updated);
  }

  // DELETE
  static Future<void> deleteExpense(int key) async {
    await _box.delete(key);
  }

  // REACTIVE LISTENABLE
  static ValueListenable<Box<Expense>> get listenable => _box.listenable();

  // HELPERS
  static double getTotalExpenses() {
    return _box.values.fold(0.0, (sum, e) => sum + e.amount);
  }

  static double getMonthlyTotal(int year, int month) {
    return _box.values
        .where((e) => e.date.year == year && e.date.month == month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }
}