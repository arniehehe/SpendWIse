// lib/services/expense_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpendWise'),
      ),

      body: Column(
        children: [

          // TOTAL CARD
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(16),
            ),

            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Expenses',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 10),

                Text(
                  '₱0.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // EMPTY MESSAGE
          const Expanded(
            child: Center(
              child: Text(
                'No expenses yet',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {

        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

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