import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:project_app/pages/auth_service.dart';
import 'package:project_app/pages/convex.dart';
import 'package:project_app/pages/home.dart';
import 'package:project_app/pages/login.dart';
import 'package:project_app/pages/signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize locale data for fr_FR
    await initializeDateFormatting('fr_FR', null);
    print('Locale data for fr_FR initialized successfully');
    // Optionally initialize en_US if needed in the future
    // await initializeDateFormatting('en_US', null);
    // print('Locale data for en_US initialized successfully');
  } catch (e) {
    print('Error initializing locale data: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  // Check if a token exists on startup
  Future<String?> _checkToken() async {
    return await _authService.getToken();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<String?>(
        future: _checkToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()), // Loading screen
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(); // If token exists, go to Home
          }
          return Login(); // Otherwise, go to Login
        },
      ),
      routes: {
        '/login': (context) => Login(),
        '/signup': (context) => SignUp(),
        '/home': (context) => HomeScreen(),
        '/ConvexBar': (context) => MyConvexBottomBar(),
      },
    );
  }
}