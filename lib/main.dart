import 'package:barcodescanner/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tab_page.dart';
import 'login_page.dart';
import 'dart:async';
import 'global.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, dynamic>> loadData() async {
    // Initialize barcode SDK
    final sdkInitResult = await initBarcodeSDK();
    
    // Check login status and load token if available
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    // If logged in, set the token in ApiService
    if (isLoggedIn) {
      final token = prefs.getString('auth_token');
      if (token != null) {
        final apiService = ApiService();
        apiService.setToken(token);
      }
    }
    
    return {
      'sdkInitialized': sdkInitResult,
      'isLoggedIn': isLoggedIn,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Storage Organizer',
      theme: ThemeData(
        scaffoldBackgroundColor: colorMainTheme,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: FutureBuilder<Map<String, dynamic>>(
        future: loadData(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              backgroundColor: colorMainTheme,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colorBlue),
                ),
              ),
            );
          }
          
          // SDK is initialized, now route based on login status
          final isLoggedIn = snapshot.data!['isLoggedIn'] as bool;
          
          if (isLoggedIn) {
            // User is logged in, go to main app
            return const TabPage();
          } else {
            // User is not logged in, go to login page
            return const LoginPage();
          }
        },
      ),
    );
  }
}
