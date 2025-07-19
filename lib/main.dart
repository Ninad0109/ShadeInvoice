import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wanderhome/theme.dart';
import 'package:wanderhome/services/invoice_service.dart';
import 'package:wanderhome/screens/home_screen.dart';

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
        title: 'WanderHome Invoice Generator',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
