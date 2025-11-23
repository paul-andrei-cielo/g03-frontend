import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:registrar_app/screens/student_dashboard.dart';

const String baseUrl = 'https://g03-backend.onrender.com';

class RequestSummaryScreen extends StatefulWidget {
  final String requestId;
  final String token;

  const RequestSummaryScreen({
    super.key,
    required this.requestId,
    required this.token,
  });

  @override
  _RequestSummaryScreenState createState() => _RequestSummaryScreenState();
}

class _RequestSummaryScreenState extends State<RequestSummaryScreen> {
  Map<String, dynamic>? requestData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchRequestData();
  }

  Future<void> fetchRequestData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/requests/viewrequest/${widget.requestId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Debug: Print the full response to check if populate worked
          print('API Response: $data');
          setState(() {
            requestData = data['request'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load request data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load request data (Status: ${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text(errorMessage)),
      );
    }

    if (requestData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('No data available')),
      );
    }

    // Extract data from requestData
    String referenceId = requestData!['reference_id'] ?? 'N/A';
    
    // Safe access to student data (handles if populate failed)
    dynamic student = requestData!['student_id'];
    String fullName = 'N/A';
    String studentNumber = 'N/A';
    if (student is Map<String, dynamic>) {
      String firstName = student['first_name'] ?? '';
      String middleName = student['middle_name'] ?? '';
      String lastName = student['last_name'] ?? '';
      String extensions = student['extensions'] ?? '';
      fullName = [firstName, middleName, lastName, extensions]
          .where((part) => part.isNotEmpty)
          .join(' ')
          .trim();
      if (fullName.isEmpty) fullName = 'N/A';
      studentNumber = student['student_number'] ?? 'N/A';
    } else {
      // Handle if not populated (e.g., fetch separately or show ID)
      print('Student not populated: $student');
    }
    
    List<dynamic> documents = requestData!['documents'] ?? [];
    String documentType = documents.map((doc) => doc['name']).join(', '); // Concatenate document names
    int copies = documents.fold(0, (sum, doc) => sum + (doc['copies'] as int)); // Sum of copies
    double totalAmount = (requestData!['total_amount'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔴 Page Header (matches other screens)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Request Summary",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.black87,
                    ),
                  ),
                  Image.asset(
                    'assets/images/Req-ITLongLogo.png',
                    height: 55,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 🔴 Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Summary of Request",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                    const SizedBox(height: 15),

                    _buildRow("Reference ID:", referenceId),
                    _buildRow("Student Name:", fullName),
                    _buildRow("Student Number:", studentNumber),
                    _buildRow("Document(s):", documentType),
                    _buildRow("Number of Copies:", "$copies"),
                    _buildRow("Total Amount:", "₱${totalAmount.toStringAsFixed(2)}"),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 🔴 Cashier Instructions
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Please present this screen to the cashier",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(Icons.receipt_long, size: 80, color: Colors.grey[600]),
                  ],
                ),
              ),

              const Spacer(),

              // 🔴 Confirm Button (same style as other screens)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => StudentDashboard(token: widget.token),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "CONFIRM",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔴 Clean, themed summary rows
  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}