import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';
import 'QrScannerScreen.dart';

class LogAndPayScreen extends StatefulWidget {
  @override
  _LogAndPayScreenState createState() => _LogAndPayScreenState();
}

class _LogAndPayScreenState extends State<LogAndPayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

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
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
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

      // Step 2: Open QR Scanner
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrScannerScreen(
            onPaymentCompleted: (result) async {
              if (result == "success") {
                final updatedTransaction = Transaction(
                  id: transactionId,
                  amount: transaction.amount,
                  category: transaction.category,
                  type: transaction.type,
                  note: transaction.note,
                  date: transaction.date,
                  status: 'completed',
                );
                await _dbHelper.updateTransaction(updatedTransaction);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Transaction completed successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Payment failed. Saved as pending."),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              Navigator.pop(context); // close scanner
            },
          ),
        ),
      );
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
      body: Padding(
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
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Log your expense first, then scan the QR to pay. Transaction updates automatically!',
                          style: TextStyle(color: Colors.blue.shade800),
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
                decoration: InputDecoration(
                  labelText: 'Amount to Pay',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
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
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
                  icon: Icon(Icons.qr_code_scanner, size: 24),
                  label: Text(
                    'Log & Scan to Pay',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Info text
              Center(
                child: Text(
                  'Your transaction will be saved before payment',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../models/transaction.dart';
// import '../database/database_helper.dart';

// class LogAndPayScreen extends StatefulWidget {
//   @override
//   _LogAndPayScreenState createState() => _LogAndPayScreenState();
// }

// class _LogAndPayScreenState extends State<LogAndPayScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _amountController = TextEditingController();
//   final _noteController = TextEditingController();
//   final DatabaseHelper _dbHelper = DatabaseHelper();

//   String _selectedCategory = 'Food';
//   DateTime _selectedDate = DateTime.now();

//   final List<String> _categories = [
//     'Food',
//     'Shopping',
//     'Transport',
//     'Bills',
//     'Entertainment',
//     'Health',
//     'Other'
//   ];

//   @override
//   void dispose() {
//     _amountController.dispose();
//     _noteController.dispose();
//     super.dispose();
//   }

//   Future<void> _logAndProceedToPay() async {
//     if (_formKey.currentState!.validate()) {
//       // Step 1: Log the transaction as 'pending'
//       final transaction = Transaction(
//         amount: double.parse(_amountController.text),
//         category: _selectedCategory,
//         type: 'expense',
//         note: _noteController.text.isEmpty ? null : _noteController.text,
//         date: _selectedDate,
//         status: 'pending',
//       );

//       final transactionId = await _dbHelper.insertTransaction(transaction);

//       // Step 2: Show payment apps chooser
//       _showPaymentAppsDialog(transactionId);
//     }
//   }

//   void _showPaymentAppsDialog(int transactionId) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Choose Payment Method',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Amount: ₹${_amountController.text}',
//               style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//             ),
//             SizedBox(height: 20),
//             GridView.count(
//               shrinkWrap: true,
//               crossAxisCount: 3,
//               children: [
//                 _buildPaymentOption('Google Pay', Icons.payment,
//                     () => _openPaymentApp('googlepay', transactionId)),
//                 _buildPaymentOption('PhonePe', Icons.phone_android,
//                     () => _openPaymentApp('phonepe', transactionId)),
//                 _buildPaymentOption('Paytm', Icons.account_balance_wallet,
//                     () => _openPaymentApp('paytm', transactionId)),
//                 _buildPaymentOption('UPI Apps', Icons.apps,
//                     () => _openPaymentApp('upi', transactionId)),
//                 _buildPaymentOption('Banking App', Icons.account_balance,
//                     () => _openPaymentApp('banking', transactionId)),
//                 _buildPaymentOption('Other', Icons.more_horiz,
//                     () => _openPaymentApp('other', transactionId)),
//               ],
//             ),
//             SizedBox(height: 20),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _showPaymentConfirmation(transactionId);
//               },
//               child: Text('Skip - I\'ll pay later'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPaymentOption(String name, IconData icon, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Card(
//         child: Padding(
//           padding: EdgeInsets.all(8.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, size: 30, color: Colors.green),
//               SizedBox(height: 8),
//               Text(
//                 name,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 12),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _openPaymentApp(String appType, int transactionId) async {
//     Navigator.pop(context); // Close the bottom sheet

//     // Simulate opening payment app
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Opening payment app...')),
//     );

//     // Wait a bit to simulate the payment app flow
//     await Future.delayed(Duration(seconds: 2));

//     // Show payment confirmation dialog
//     _showPaymentConfirmation(transactionId);
//   }

//   void _showPaymentConfirmation(int transactionId) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Text('Payment Status'),
//         content: Text('Was your payment successful?'),
//         actions: [
//           TextButton(
//             onPressed: () async {
//               // Payment failed - keep as pending
//               Navigator.pop(context);
//               Navigator.pop(context, false);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(
//                       'Transaction saved as pending. You can complete it later.'),
//                   backgroundColor: Colors.orange,
//                 ),
//               );
//             },
//             child: Text('No', style: TextStyle(color: Colors.red)),
//           ),
//           TextButton(
//             onPressed: () async {
//               // Payment successful - mark as completed
//               final transaction = await _getTransactionById(transactionId);
//               if (transaction != null) {
//                 final updatedTransaction = Transaction(
//                   id: transaction.id,
//                   amount: transaction.amount,
//                   category: transaction.category,
//                   type: transaction.type,
//                   note: transaction.note,
//                   date: transaction.date,
//                   status: 'completed',
//                 );
//                 await _dbHelper.updateTransaction(updatedTransaction);
//               }

//               Navigator.pop(context);
//               Navigator.pop(context, true);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Transaction completed successfully!'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             },
//             child: Text('Yes', style: TextStyle(color: Colors.green)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<Transaction?> _getTransactionById(int id) async {
//     final transactions = await _dbHelper.getAllTransactions();
//     try {
//       return transactions.firstWhere((t) => t.id == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Log & Pay'),
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Info Card
//               Card(
//                 color: Colors.blue.shade50,
//                 child: Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Row(
//                     children: [
//                       Icon(Icons.info, color: Colors.blue),
//                       SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           'Log your expense first, then pay through your preferred app. This ensures 100% accuracy!',
//                           style: TextStyle(color: Colors.blue.shade800),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: 24),

//               // Amount Field
//               TextFormField(
//                 controller: _amountController,
//                 keyboardType: TextInputType.numberWithOptions(decimal: true),
//                 decoration: InputDecoration(
//                   labelText: 'Amount to Pay',
//                   prefixText: '₹ ',
//                   border: OutlineInputBorder(),
//                   filled: true,
//                   fillColor: Colors.grey.shade50,
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter an amount';
//                   }
//                   if (double.tryParse(value) == null) {
//                     return 'Please enter a valid number';
//                   }
//                   if (double.parse(value) <= 0) {
//                     return 'Amount must be greater than 0';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 20),

//               // Category Dropdown
//               DropdownButtonFormField<String>(
//                 value: _selectedCategory,
//                 decoration: InputDecoration(
//                   labelText: 'Category',
//                   border: OutlineInputBorder(),
//                   filled: true,
//                   fillColor: Colors.grey.shade50,
//                 ),
//                 items: _categories
//                     .map((category) => DropdownMenuItem(
//                           value: category,
//                           child: Text(category),
//                         ))
//                     .toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedCategory = value!;
//                   });
//                 },
//               ),
//               SizedBox(height: 20),

//               // Note Field
//               TextFormField(
//                 controller: _noteController,
//                 decoration: InputDecoration(
//                   labelText: 'Note (optional)',
//                   border: OutlineInputBorder(),
//                   filled: true,
//                   fillColor: Colors.grey.shade50,
//                 ),
//                 maxLines: 2,
//               ),
//               SizedBox(height: 30),

//               // Log & Pay Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton.icon(
//                   onPressed: _logAndProceedToPay,
//                   icon: Icon(Icons.payment, size: 24),
//                   label: Text(
//                     'Log & Proceed to Pay',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),

//               // Info text
//               Center(
//                 child: Text(
//                   'Your transaction will be saved before payment',
//                   style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
