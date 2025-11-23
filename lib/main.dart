import 'package:flutter/material.dart';
import 'package:registrar_app/screens/staff_register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/student_dashboard.dart'; 
import 'screens/forgot_password_screen.dart';
import 'screens/registrar_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Req-IT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Montserrat',
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/register': (context) => const RegisterScreen(),
        '/staff_register': (context) => const StaffRegisterScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/student_dashboard') {
          final token = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => StudentDashboard(token: token),
          );
        } else if (settings.name == '/registrar_dashboard') {
          final token = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => RegistrarDashboard(token: token),
          );
        }
        return null;
      },
    );
  }
}
