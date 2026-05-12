// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/export_service.dart';
import '../widgets/expense_tile.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ExpenseCategory? _selectedCategory;

  String _label(ExpenseCategory? cat) {
    if (cat == null) return 'All';
    switch (cat) {
      case ExpenseCategory.food:          return 'Food';
      case ExpenseCategory.transport:     return 'Transport';
      case ExpenseCategory.shopping:      return 'Shopping';
      case ExpenseCategory.utilities:     return 'Utilities';
      case ExpenseCategory.entertainment: return 'Entertainment';
      case ExpenseCategory.other:         return 'Other';
    }
  }

  // ── Exercise 2: Read budget from Hive settings box ──────────────────────
  double get _budget {
    final box = Hive.box('settings');
    return (box.get('monthly_budget') ?? 0.0) as double;
  }

  // ── Exercise 2: Show set-budget dialog ───────────────────────────────────
  void _showSetBudgetDialog() {
    final ctrl = TextEditingController(
      text: _budget > 0 ? _budget.toStringAsFixed(2) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '₱ ',
            hintText: 'e.g. 5000.00',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text.trim());
              if (val != null && val > 0) {
                await Hive.box('settings').put('monthly_budget', val);
              }
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {}); // Refresh budget display
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Exercise 3: Export current month ────────────────────────────────────
  Future<void> _exportMonth() async {
    try {
      final path = await ExportService.exportCurrentMonth();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to: $path'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpendWise', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Exercise 3: Export button
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Export this month',
            onPressed: _exportMonth,
          ),
          // Exercise 2: Budget button
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Set Budget',
            onPressed: _showSetBudgetDialog,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'SpendWise',
              applicationVersion: '1.0.0',
              children: [const Text('A personal expense tracker built with Hive.')],
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Expense>>(
        valueListenable: ExpenseService.listenable,
        builder: (context, box, _) {
          final double total = box.values.fold(0.0, (s, e) => s + e.amount);
          final double budget = _budget;
          final double percentage =
              budget > 0 ? (total / budget).clamp(0.0, 1.0) : 0.0;

          // Exercise 2: Show budget alert when >= 80%
          if (percentage >= 0.8 && budget > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  '⚠️ Budget Alert: You\'ve used ${(percentage * 100).toStringAsFixed(0)}% of your monthly budget!',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ));
            });
          }

          final List<Expense> expenses = _selectedCategory == null
              ? ExpenseService.getAllExpenses()
              : ExpenseService.getExpensesByCategory(_selectedCategory!);

          expenses.sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              _buildSummaryCard(total, box.length, budget, percentage),
              _buildFilterChips(),
              Expanded(child: _buildExpenseList(expenses)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildSummaryCard(double total, int count, double budget, double percentage) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total Spending',
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                  Text('$count expense${count == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12, color: Colors.black45)),
                ]),
                Text(
                  '₱${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ],
            ),
            // Exercise 2: Budget progress bar
            if (budget > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Budget: ₱${budget.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Text('${(percentage * 100).toStringAsFixed(0)}% used',
                      style: TextStyle(
                          fontSize: 12,
                          color: percentage >= 0.8 ? Colors.red : Colors.black54,
                          fontWeight: percentage >= 0.8
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[300],
                  color: percentage >= 0.8 ? Colors.red : Colors.indigo,
                  minHeight: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final categories = [null, ...ExpenseCategory.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((cat) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(_label(cat)),
            selected: _selectedCategory == cat,
            onSelected: (_) => setState(() => _selectedCategory = cat),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildExpenseList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No expenses yet!',
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Tap the button below to add your first expense.',
              style: TextStyle(color: Colors.grey[400])),
        ]),
      );
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (ctx, i) {
        final expense = expenses[i];
        final int key = expense.key as int;
        return ExpenseTile(
          expense: expense,
          onDelete: () => ExpenseService.deleteExpense(key),
          onEdit: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) =>
                  EditExpenseScreen(expense: expense, expenseKey: key),
            ),
          ),
        );
      },
    );
  }
}