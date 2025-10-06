import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Transaction> _transactions = [];
  String _selectedPeriod = 'This Month';
  bool _isLoading = true;

  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last Month',
    'This Year'
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final allTransactions = await _dbHelper.getAllTransactions();

    final filtered =
        _filterTransactionsByPeriod(allTransactions, _selectedPeriod);

    setState(() {
      _transactions = filtered;
      _isLoading = false;
    });
  }

  List<Transaction> _filterTransactionsByPeriod(
      List<Transaction> transactions, String period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (period) {
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return transactions.where((t) {
      return t.date.isAfter(startDate.subtract(Duration(days: 1))) &&
          t.date.isBefore(endDate.add(Duration(days: 1))) &&
          t.status == 'completed';
    }).toList();
  }

  Map<String, double> _getCategoryExpenses() {
    final categoryTotals = <String, double>{};

    for (var transaction in _transactions) {
      if (transaction.type == 'expense') {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return categoryTotals;
  }

  double _getTotalIncome() {
    return _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _getTotalExpenses() {
    return _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  List<Color> _chartColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadTransactions();
            },
            itemBuilder: (context) => _periods
                .map((period) =>
                    PopupMenuItem(value: period, child: Text(period)))
                .toList(),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedPeriod, style: TextStyle(fontSize: 14)),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No transactions for this period',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: Colors.green.shade50,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(Icons.arrow_upward,
                                        color: Colors.green),
                                    SizedBox(height: 8),
                                    Text('Income',
                                        style:
                                            TextStyle(color: Colors.grey[600])),
                                    SizedBox(height: 4),
                                    Text(
                                      '₹${_getTotalIncome().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Card(
                              color: Colors.red.shade50,
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(Icons.arrow_downward,
                                        color: Colors.red),
                                    SizedBox(height: 8),
                                    Text('Expenses',
                                        style:
                                            TextStyle(color: Colors.grey[600])),
                                    SizedBox(height: 4),
                                    Text(
                                      '₹${_getTotalExpenses().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Expense Breakdown Title
                      Text(
                        'Expense Breakdown',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),

                      // Pie Chart
                      if (_getTotalExpenses() > 0)
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 250,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _buildPieChartSections(),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 50,
                                      borderData: FlBorderData(show: false),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                _buildLegend(),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 24),

                      // Category List
                      Text(
                        'Category Details',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      ..._buildCategoryList(),
                    ],
                  ),
                ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final categoryExpenses = _getCategoryExpenses();
    final total = _getTotalExpenses();

    int colorIndex = 0;
    return categoryExpenses.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final color = _chartColors[colorIndex % _chartColors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: color,
        radius: 80,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    final categoryExpenses = _getCategoryExpenses();
    int colorIndex = 0;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: categoryExpenses.entries.map((entry) {
        final color = _chartColors[colorIndex % _chartColors.length];
        colorIndex++;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6),
            Text(entry.key, style: TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  List<Widget> _buildCategoryList() {
    final categoryExpenses = _getCategoryExpenses();
    final sortedEntries = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int colorIndex = 0;
    return sortedEntries.map((entry) {
      final percentage = (entry.value / _getTotalExpenses() * 100);
      final color = _chartColors[colorIndex % _chartColors.length];
      colorIndex++;

      return Card(
        margin: EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(_getCategoryIcon(entry.key), color: color),
          ),
          title: Text(
            entry.key,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${entry.value.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Transport':
        return Icons.directions_car;
      case 'Bills':
        return Icons.receipt;
      case 'Entertainment':
        return Icons.movie;
      case 'Health':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }
}
