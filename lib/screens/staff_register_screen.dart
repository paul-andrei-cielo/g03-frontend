import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StaffRegisterScreen extends StatefulWidget {
  const StaffRegisterScreen({super.key});

  @override
  State<StaffRegisterScreen> createState() => _StaffRegisterScreenState();
}

Widget _buildPlainInputField({
  required TextEditingController controller,
  required String hint,
  bool isRequired = true,
}) {
  return TextFormField(
    controller: controller,
    style: const TextStyle(color: Colors.black),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.black54,
        fontFamily: 'Montserrat',
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
    validator: (value) {
      if (isRequired && (value == null || value.isEmpty)) {
        return 'Please enter your ${hint.toLowerCase()}';
      }
      return null;
    },
  );
}

class _StaffRegisterScreenState extends State<StaffRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _extensionsController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false; // For showing a loading indicator

  @override
  void dispose() {
    _employeeIdController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _extensionsController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true); // Show loading

    final employeeNumber = _employeeIdController.text.trim();
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final extensions = _extensionsController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final String baseUrl = 'https://g03-backend.onrender.com';
    final String endpoint = '$baseUrl/user/staffregistration';

    final Map<String, dynamic> body = {
      "employee_number": employeeNumber,
      "first_name": firstName,
      "middle_name": middleName.isEmpty ? null : middleName,
      "last_name": lastName,
      "extensions": extensions.isEmpty ? null : extensions,
      "email": email,
      "password": password,
    };

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      final isAdded = data['isAdded'];

      if (response.statusCode == 200 && isAdded != null && isAdded['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff account created successfully!')),
        );
        Navigator.pushNamed(context, '/login', arguments: {'loginType': 'Employee'});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAdded?['message'] ?? "Registration failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false); // Hide loading
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
                      // Logo
                      Image.asset(
                        'assets/images/sdca_whitelogo.png',
                        height: 60,
                      ),
                      const SizedBox(height: 15),

                      const Text(
                        "STAFF REGISTRATION",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Employee ID
                      _buildInputField(
                        controller: _employeeIdController,
                        hint: "EMPLOYEE ID",
                        icon: Icons.badge,
                      ),
                      const SizedBox(height: 15),

                      // Name label
                      Row(
                        children: const [
                          Icon(Icons.person, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "Name",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _buildPlainInputField(
                        controller: _firstNameController,
                        hint: "FIRST NAME",
                        isRequired: true,
                      ),
                      const SizedBox(height: 15),
                      _buildPlainInputField(
                        controller: _middleNameController,
                        hint: "MIDDLE NAME",
                        isRequired: false,
                      ),
                      const SizedBox(height: 15),
                      _buildPlainInputField(
                        controller: _lastNameController,
                        hint: "LAST NAME",
                        isRequired: true,
                      ),
                      const SizedBox(height: 20),
                      _buildPlainInputField( 
                        controller: _extensionsController,
                        hint: "EXTENSIONS",
                        isRequired: false,
                      ),
                      const SizedBox(height: 20),

                      // School Email
                      _buildInputField(
                        controller: _emailController,
                        hint: "SCHOOL EMAIL",
                        icon: Icons.email,
                      ),
                      const SizedBox(height: 15),

                      // Password
                      _buildInputField(
                        controller: _passwordController,
                        hint: "PASSWORD",
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      const SizedBox(height: 15),

                      // Confirm Password
                      _buildInputField(
                        controller: _confirmPasswordController,
                        hint: "CONFIRM PASSWORD",
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 30),

                      // Register Button with Loading
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "REGISTER",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),

                      // Back to Login
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "ALREADY HAVE AN ACCOUNT?\nLOGIN HERE",
                          textAlign: TextAlign.center,
                          style: TextStyle(
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

  /// 🧾 Custom Input Field Builder (same as Student Register)
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
          padding: const EdgeInsets.all(8.0),
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your ${hint.toLowerCase()}';
        }
        if (hint.contains("CONFIRM") &&
            value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }
}