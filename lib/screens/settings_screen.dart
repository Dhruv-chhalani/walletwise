import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isDarkMode = false;
  String _currency = 'INR (₹)';

  final List<String> _currencies = [
    'INR (₹)',
    'USD (\$)',
    'EUR (€)',
    'GBP (£)',
    'JPY (¥)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // App Settings Section
          _buildSectionHeader('Appearance'),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              title: Text('Dark Mode'),
              subtitle: Text('Switch between light and dark theme'),
              value: _isDarkMode,
              activeColor: Colors.green,
              secondary: Icon(
                _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Colors.green,
              ),
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Dark mode will be implemented in future update'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),

          // Currency Settings
          _buildSectionHeader('Currency'),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.currency_rupee, color: Colors.green),
              title: Text('Currency'),
              subtitle: Text(_currency),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showCurrencyDialog();
              },
            ),
          ),

          // Data Management Section
          _buildSectionHeader('Data Management'),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.file_download, color: Colors.green),
              title: Text('Export Data'),
              subtitle: Text('Export transactions to CSV file'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _exportData();
              },
            ),
          ),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: Text('Clear All Data'),
              subtitle: Text('Delete all transactions and budgets'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showClearDataDialog();
              },
            ),
          ),

          // Categories Management
          _buildSectionHeader('Categories'),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.category, color: Colors.green),
              title: Text('Manage Categories'),
              subtitle: Text('Add or edit transaction categories'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category management coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),

          // About Section
          _buildSectionHeader('About'),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.info, color: Colors.green),
              title: Text('About WalletWise'),
              subtitle: Text('Version 1.0.0'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showAboutDialog();
              },
            ),
          ),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.help, color: Colors.green),
              title: Text('Help & Support'),
              subtitle: Text('Get help using the app'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showHelpDialog();
              },
            ),
          ),
          SizedBox(height: 32),

          // App Info Footer
          Center(
            child: Column(
              children: [
                Icon(Icons.account_balance_wallet,
                    size: 48, color: Colors.grey[400]),
                SizedBox(height: 8),
                Text(
                  'WalletWise',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your Personal Finance Tracker',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _currencies.map((currency) {
            return RadioListTile<String>(
              title: Text(currency),
              value: currency,
              groupValue: _currency,
              activeColor: Colors.green,
              onChanged: (value) {
                setState(() {
                  _currency = value!;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Currency changed to $value'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final transactions = await _dbHelper.getAllTransactions();

      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No transactions to export')),
        );
        return;
      }

      // Create CSV content
      String csvContent = 'Date,Type,Category,Amount,Note,Status\n';
      for (var transaction in transactions) {
        final date = DateFormat('yyyy-MM-dd').format(transaction.date);
        final note = transaction.note?.replaceAll(',', ';') ?? '';
        csvContent +=
            '${date},${transaction.type},${transaction.category},${transaction.amount},${note},${transaction.status}\n';
      }

      // Show success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('Export Ready'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${transactions.length} transactions ready to export.'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  csvContent.substring(0,
                          csvContent.length > 200 ? 200 : csvContent.length) +
                      '...',
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'In a production app, this would save to your device.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Clear All Data?'),
          ],
        ),
        content: Text(
          'This will permanently delete all your transactions and budgets. This action cannot be undone!',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Get all transactions and budgets, then delete them
              final transactions = await _dbHelper.getAllTransactions();
              final budgets = await _dbHelper.getAllBudgets();

              for (var transaction in transactions) {
                await _dbHelper.deleteTransaction(transaction.id!);
              }

              for (var budget in budgets) {
                await _dbHelper.deleteBudget(budget.id!);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All data cleared successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('About WalletWise'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WalletWise - Personal Finance Tracker',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Log-Then-Pay workflow'),
            Text('• QR code payment integration'),
            Text('• Budget management'),
            Text('• Visual reports and analytics'),
            Text('• Transaction history'),
            SizedBox(height: 16),
            Text(
              'WalletWise helps you track your finances effortlessly with the innovative Log-Then-Pay feature!',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Support'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem('How to use Log & Pay?',
                  'Tap the + button on Home, select Log & Pay, enter details, then scan QR or choose payment app.'),
              _buildHelpItem('How to set budgets?',
                  'Go to Budgets tab, tap +, select category and set your monthly limit.'),
              _buildHelpItem('How to view reports?',
                  'Navigate to Reports tab to see spending breakdown and analytics.'),
              _buildHelpItem('How to edit transactions?',
                  'Long press on any transaction in History to delete it.'),
              SizedBox(height: 16),
              Text(
                'For more help, contact: support@walletwise.app',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String question, String answer) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
