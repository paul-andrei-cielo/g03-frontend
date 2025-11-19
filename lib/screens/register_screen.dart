import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _status;
  String _selectedProgram = '';
  String _selectedRole = "Student";

  final List<String> _programs = [
    "Bachelor of Arts in Communication",
    "Bachelor of Multimedia Arts",
    "Bachelor of Pharmacy",
    "Bachelor of Science in Accountancy",
    "Bachelor of Science in Business Administration",
    "Bachelor of Science in Education",
    "Bachelor of Science in Hospitality Management",
    "Bachelor of Science in Information Technology",
    "Bachelor of Science in Medical Technology",
    "Bachelor of Science in Nursing",
    "Bachelor of Science in Psychology",
    "Bachelor of Science in Physical Therapy",
  ];

  @override
  void dispose() {
    _studentNumberController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> registerStudent(Map<String, dynamic> body) async {
    final String baseUrl = 'https://g03-backend.onrender.com';
    final url = Uri.parse('$baseUrl/user/studentregistration');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  void _register() async {
    // Trim all input fields
    final studentNumber = _studentNumberController.text.trim();
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate form
    if (!_formKey.currentState!.validate()) return;

    if (studentNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student number cannot be empty')),
      );
      return;
    }

    if (_selectedProgram.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your program')),
      );
      return;
    }

    if (_status == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your status')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

    final body = {
      "student_number": studentNumber,
      "first_name": firstName,
      "middle_name": middleName,
      "last_name": lastName,
      "extensions": "",
      "email": email,
      "password": password,
      "program": _selectedProgram,
      "year_level": "1",
      "status": _status,
    };

    try {
      final result = await registerStudent(body);

      if (result['isAdded']['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        Navigator.pushNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['isAdded']['message'] ?? 'Registration failed'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
                      // Logo
                      Image.asset(
                        'assets/images/sdca_whitelogo.png',
                        height: 60,
                      ),
                      const SizedBox(height: 15),

                      const Text(
                        "STUDENT REGISTRATION",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Student number and email
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _studentNumberController,
                              hint: "STUDENT NUMBER",
                              icon: Icons.badge,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildInputField(
                              controller: _emailController,
                              hint: "STUDENT EMAIL",
                              icon: Icons.email,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Name
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
                      ),
                      const SizedBox(height: 15),
                      _buildPlainInputField(
                        controller: _middleNameController,
                        hint: "MIDDLE NAME",
                      ),
                      const SizedBox(height: 15),
                      _buildPlainInputField(
                        controller: _lastNameController,
                        hint: "LAST NAME",
                      ),
                      const SizedBox(height: 20),

                      // Program Dropdown
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red[700],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedProgram.isEmpty ? null : _selectedProgram,
                          dropdownColor: Colors.red[700],
                          iconEnabledColor: Colors.white,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          hint: const Text(
                            "SELECT PROGRAM",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.white,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                          ),
                          items: _programs
                              .map((program) => DropdownMenuItem(
                                    value: program,
                                    child: Text(
                                      program,
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedProgram = value!);
                          },
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Status Dropdown
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red[700],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          dropdownColor: Colors.red[700],
                          iconEnabledColor: Colors.white,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          hint: const Text(
                            "SELECT STATUS",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.white,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(value: "Enrolled", child: Text("Enrolled", style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: "Unenrolled", child: Text("Unenrolled", style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: "Graduated", child: Text("Graduated", style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: "On Leave", child: Text("On Leave", style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: "Dropped", child: Text("Dropped", style: TextStyle(color: Colors.white))),
                          ],
                          onChanged: (value) {
                            setState(() => _status = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Password Fields
                      _buildInputField(
                        controller: _passwordController,
                        hint: "CREATE PASSWORD",
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      const SizedBox(height: 15),
                      _buildInputField(
                        controller: _confirmPasswordController,
                        hint: "CONFIRM PASSWORD",
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 25),

                      // Register Button
                      ElevatedButton(
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
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text(
                          "ALREADY HAVE AN ACCOUNT?\nLOGIN HERE",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black, fontFamily: 'Montserrat'),
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
        hintStyle: const TextStyle(color: Colors.black54, fontFamily: 'Montserrat'),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
      validator: (value) => value!.trim().isEmpty ? 'Please enter your ${hint.toLowerCase()}' : null,
    );
  }

  Widget _buildPlainInputField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black, fontFamily: 'Montserrat'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54, fontFamily: 'Montserrat'),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
      validator: (value) => value!.trim().isEmpty ? 'Please enter your ${hint.toLowerCase()}' : null,
    );
  }

  Widget _buildRoleOption(String role) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(role.toUpperCase(), style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat')),
        Radio<String>(
          value: role,
          groupValue: _selectedRole,
          activeColor: Colors.white,
          onChanged: (value) {
            setState(() {
              _selectedRole = value!;
            });
          },
        ),
      ],
    );
  }
}


