import 'package:flutter/material.dart';
import 'package:registrar_app/screens/student_dashboard.dart';

class RequestSummaryScreen extends StatelessWidget {
  final String requestId;
  final String documentType;
  final int copies;
  final double totalAmount;
  final String token;

  const RequestSummaryScreen({
    super.key,
    required this.requestId,
    required this.documentType,
    required this.copies,
    required this.totalAmount,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
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

                    _buildRow("Request ID:", requestId),
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
                        builder: (context) => StudentDashboard(token: token),
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
