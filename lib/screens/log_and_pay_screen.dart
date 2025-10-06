import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';
import 'QrScannerScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class LogAndPayScreen extends StatefulWidget {
  @override
  _LogAndPayScreenState createState() => _LogAndPayScreenState();
}

class _LogAndPayScreenState extends State<LogAndPayScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  int? _pendingTransactionId;
  bool _isPaymentInProgress = false;

  final List<String> _categories = [
    'Food',
    'Shopping',
    'Transport',
    'Bills',
    'Entertainment',
    'Health',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back from background (user returns from payment app)
    if (state == AppLifecycleState.resumed && _isPaymentInProgress) {
      _isPaymentInProgress = false;
      Future.delayed(Duration(milliseconds: 800), () {
        if (_pendingTransactionId != null && mounted) {
          _showPaymentConfirmation(_pendingTransactionId!);
        }
      });
    }
  }

  Future<void> _logAndProceedToPay() async {
    if (_formKey.currentState!.validate()) {
      // Step 1: Log transaction as pending
      final transaction = Transaction(
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        type: 'expense',
        note: _noteController.text.isEmpty ? null : _noteController.text,
        date: _selectedDate,
        status: 'pending',
      );

      final transactionId = await _dbHelper.insertTransaction(transaction);
      _pendingTransactionId = transactionId;

      // Step 2: Show payment method chooser
      _showPaymentMethodChooser(transactionId);
    }
  }

  void _showPaymentMethodChooser(int transactionId) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Payment Method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Amount: ₹${_amountController.text}',
              style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            // QR Scanner Option (Primary)
            Card(
              elevation: 4,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.qr_code_scanner, color: Colors.white),
                ),
                title: Text('Scan QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Scan merchant\'s UPI QR code'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pop(context);
                  _openQRScanner(transactionId);
                },
              ),
            ),
            SizedBox(height: 12),
            
            // Other Payment Apps
            Text('Or choose payment app:', style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 12),
            
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildPaymentOption('Google Pay', Icons.payment, () {
                  Navigator.pop(context);
                  _showUpiInputDialog('gpay', transactionId);
                }),
                _buildPaymentOption('PhonePe', Icons.phone_android, () {
                  Navigator.pop(context);
                  _showUpiInputDialog('phonepe', transactionId);
                }),
                _buildPaymentOption('Paytm', Icons.account_balance_wallet, () {
                  Navigator.pop(context);
                  _showUpiInputDialog('paytm', transactionId);
                }),
              ],
            ),
            SizedBox(height: 16),
            
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showPaymentConfirmation(transactionId);
              },
              child: Text('I\'ll pay later', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpiInputDialog(String appType, int transactionId) {
    final upiController = TextEditingController();
    final nameController = TextEditingController(text: 'Merchant');
    String inputType = 'UPI ID'; // or 'Phone'

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(_getPaymentAppIcon(appType), color: Colors.green),
              SizedBox(width: 12),
              Text('Enter Payment Details'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: ₹${_amountController.text}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                SizedBox(height: 16),
                
                // Toggle between UPI ID and Phone
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text('UPI ID'),
                        selected: inputType == 'UPI ID',
                        selectedColor: Colors.green.shade100,
                        onSelected: (selected) {
                          setState(() {
                            inputType = 'UPI ID';
                            upiController.clear();
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text('Phone Number'),
                        selected: inputType == 'Phone',
                        selectedColor: Colors.green.shade100,
                        onSelected: (selected) {
                          setState(() {
                            inputType = 'Phone';
                            upiController.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // UPI ID / Phone Number Input
                TextField(
                  controller: upiController,
                  keyboardType: inputType == 'Phone' 
                      ? TextInputType.phone 
                      : TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: inputType == 'UPI ID' 
                        ? 'Enter UPI ID (e.g., user@paytm)' 
                        : 'Enter Phone Number',
                    hintText: inputType == 'UPI ID' 
                        ? 'username@bank' 
                        : '9876543210',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      inputType == 'UPI ID' ? Icons.alternate_email : Icons.phone,
                      color: Colors.green,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Merchant Name (Optional)
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Payee Name (Optional)',
                    hintText: 'Shop/Person name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, color: Colors.green),
                  ),
                ),
                SizedBox(height: 12),
                
                // Info text
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your ${_getAppName(appType)} app will open for payment',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (upiController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter ${inputType}')),
                  );
                  return;
                }
                
                String upiId = upiController.text.trim();
                
                // If phone number, convert to UPI format for the selected app
                if (inputType == 'Phone') {
                  upiId = _convertPhoneToUPI(upiId, appType);
                }
                
                Navigator.pop(context);
                _openPaymentApp(appType, transactionId, upiId, nameController.text.trim());
              },
              icon: Icon(Icons.payment),
              label: Text('Proceed to Pay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _convertPhoneToUPI(String phone, String appType) {
    // Remove any spaces or special characters
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Convert phone to UPI based on app
    switch (appType) {
      case 'gpay':
        return '$phone@okaxis'; // Google Pay uses various banks
      case 'phonepe':
        return '$phone@ybl'; // PhonePe uses Yes Bank
      case 'paytm':
        return '$phone@paytm'; // Paytm
      default:
        return '$phone@paytm';
    }
  }

  IconData _getPaymentAppIcon(String appType) {
    switch (appType) {
      case 'gpay':
        return Icons.payment;
      case 'phonepe':
        return Icons.phone_android;
      case 'paytm':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  String _getAppName(String appType) {
    switch (appType) {
      case 'gpay':
        return 'Google Pay';
      case 'phonepe':
        return 'PhonePe';
      case 'paytm':
        return 'Paytm';
      default:
        return 'Payment';
    }
  }

  Widget _buildPaymentOption(String name, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.green),
              SizedBox(height: 6),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openQRScanner(int transactionId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScannerScreen(transactionId: transactionId),
      ),
    );

    // If QR scanner returned 'launched', it means payment app was opened
    if (result == 'launched') {
      _isPaymentInProgress = true;
      // Wait for user to return, then show confirmation dialog
      // (handled by didChangeAppLifecycleState)
    }
  }

  Future<void> _openPaymentApp(String appType, int transactionId, String upiId, String payeeName) async {
    _isPaymentInProgress = true;
    _pendingTransactionId = transactionId;
    
    // Create UPI payment URL with actual details
    final amount = _amountController.text;
    final name = payeeName.isNotEmpty ? payeeName : 'Merchant';
    
    String upiUrl = '';
    
    // Create proper UPI deep link for each app
    switch (appType) {
      case 'gpay':
        upiUrl = 'tez://upi/pay?pa=$upiId&pn=$name&am=$amount&cu=INR&tn=${_selectedCategory}';
        break;
      case 'phonepe':
        upiUrl = 'phonepe://pay?pa=$upiId&pn=$name&am=$amount&cu=INR&tn=${_selectedCategory}';
        break;
      case 'paytm':
        upiUrl = 'paytmmp://pay?pa=$upiId&pn=$name&am=$amount&cu=INR&tn=${_selectedCategory}';
        break;
    }
    
    try {
      final uri = Uri.parse(upiUrl);
      bool launched = await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        // If specific app didn't open, try generic UPI
        _openGenericUPI(transactionId, upiId, name);
      }
    } catch (e) {
      // If error, try generic UPI
      _openGenericUPI(transactionId, upiId, name);
    }
  }

  Future<void> _openGenericUPI(int transactionId, String upiId, String payeeName) async {
    try {
      final amount = _amountController.text;
      final name = payeeName.isNotEmpty ? payeeName : 'Merchant';
      
      // Generic UPI payment URL
      final upiUrl = 'upi://pay?pa=$upiId&pn=$name&am=$amount&cu=INR&tn=${_selectedCategory}';
      final uri = Uri.parse(upiUrl);
      
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        _isPaymentInProgress = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No UPI apps found. Please install a UPI payment app.'),
            backgroundColor: Colors.red,
          ),
        );
        _showPaymentConfirmation(transactionId);
      }
    } catch (e) {
      _isPaymentInProgress = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open payment app: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _showPaymentConfirmation(transactionId);
    }
  }

  void _showPaymentConfirmation(int transactionId) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.green),
            SizedBox(width: 12),
            Text('Payment Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Did you complete the payment successfully?'),
            SizedBox(height: 12),
            Text(
              'Amount: ₹${_amountController.text}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Category: $_selectedCategory',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              // Payment failed - keep as pending
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, false); // Close log & pay screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transaction saved as pending. Complete it from History.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: Icon(Icons.close, color: Colors.red),
            label: Text('No / Failed', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Payment successful - mark as completed
              final transaction = await _getTransactionById(transactionId);
              if (transaction != null) {
                final updatedTransaction = Transaction(
                  id: transaction.id,
                  amount: transaction.amount,
                  category: transaction.category,
                  type: transaction.type,
                  note: transaction.note,
                  date: transaction.date,
                  status: 'completed',
                );
                await _dbHelper.updateTransaction(updatedTransaction);
              }

              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Close log & pay screen with success
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Transaction completed successfully!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(Icons.check_circle),
            label: Text('Yes / Success'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<Transaction?> _getTransactionById(int id) async {
    final transactions = await _dbHelper.getAllTransactions();
    try {
      return transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log & Pay'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Log your expense first, then pay via QR scan or payment app. Transaction updates automatically!',
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Amount to Pay',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.category, color: Colors.green),
                ),
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              SizedBox(height: 20),

              // Note Field
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(Icons.note, color: Colors.green),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 30),

              // Log & Pay Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _logAndProceedToPay,
                  icon: Icon(Icons.qr_code_scanner, size: 26),
                  label: Text(
                    'Log & Proceed to Pay',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Info text
              Center(
                child: Column(
                  children: [
                    Text(
                      'Transaction will be logged before payment',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'You can confirm payment status when you return',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
