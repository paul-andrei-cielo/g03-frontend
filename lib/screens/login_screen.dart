import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  String _loginType = 'Student'; // Default login type

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    final id = _idController.text.trim();
    final password = _passwordController.text.trim();

    final String baseUrl = 'https://g03-backend.onrender.com';

    final String endpoint = _loginType == 'Student'
        ? '$baseUrl/user/studentlogin'
        : '$baseUrl/user/stafflogin';

    final Map<String, dynamic> body = _loginType == 'Student'
        ? {"student_number": id, "password": password}
        : {"employee_number": id, "password": password};

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Login failed")),
        );
        return;
      }

      final String token = data['token'];

      if (_loginType == 'Student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDashboard(token: token),
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/registrar_dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: screenWidth < 800 ? 420 : 750,
              decoration: BoxDecoration(
                color: Colors.red[900],
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(30),
              child: Form(
                key: _formKey,
                child: DefaultTextStyle(
                  style: const TextStyle(fontFamily: 'Montserrat'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/sdca_whitelogo.png',
                        height: 60,
                      ),
                      const SizedBox(height: 15),

                      const Text(
                        "LOGIN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLoginTypeOption(
                            type: 'Student',
                            icon: Icons.school,
                            label: 'Student',
                          ),
                          const SizedBox(width: 25),
                          _buildLoginTypeOption(
                            type: 'Employee',
                            icon: Icons.business_center,
                            label: 'Registrar Staff',
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      _buildInputField(
                        controller: _idController,
                        hint: _loginType == 'Student'
                            ? "STUDENT NUMBER"
                            : "EMPLOYEE ID",
                        icon: Icons.badge,
                      ),
                      const SizedBox(height: 20),

                      _buildInputField(
                        controller: _passwordController,
                        hint: "PASSWORD",
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/forgot_password');
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () {
                          if (_loginType == 'Student') {
                            Navigator.pushNamed(context, '/register');
                          } else {
                            Navigator.pushNamed(context, '/staff_register');
                          }
                        },
                        child: Text(
                          "DON’T HAVE AN ACCOUNT?\nREGISTER HERE",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTypeOption({
    required String type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _loginType == type;
    return GestureDetector(
      onTap: () => setState(() => _loginType = type),
      child: Row(
        children: [
          Radio<String>(
            value: type,
            groupValue: _loginType,
            activeColor: Colors.white,
            onChanged: (value) => setState(() => _loginType = value!),
          ),
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white70,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.black54,
          fontFamily: 'Montserrat',
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) =>
          value!.isEmpty ? 'Please enter your ${hint.toLowerCase()}' : null,
    );
  }
}


