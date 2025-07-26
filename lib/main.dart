import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadeinvoice/theme.dart';
import 'package:shadeinvoice/services/invoice_service.dart';
import 'package:shadeinvoice/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InvoiceService(),
      child: MaterialApp(
        title: 'BillSnap',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
