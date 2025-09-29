import 'package:flutter/material.dart';
import 'main_navigation.dart';

void main() {
  runApp(WalletWiseApp());
}

class WalletWiseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WalletWise',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: MainNavigation(),
    );
  }
}
