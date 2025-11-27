import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'student_request_form.dart';
import 'student_all_requests_screen.dart';
import 'student_tracking_screen.dart';
import 'student_dashboard.dart';
import 'student_notifications_screen.dart';

const String baseUrl = 'https://g03-backend.onrender.com';

class StudentNotificationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> notification;
  final String token;

  const StudentNotificationDetailScreen({
    super.key,
    required this.notification,
    required this.token,
  });

  @override
  State<StudentNotificationDetailScreen> createState() => _StudentNotificationDetailScreenState();
}

class _StudentNotificationDetailScreenState extends State<StudentNotificationDetailScreen> {
  bool isCollapsed = false;
  Map<String, dynamic>? request; // Assuming 'request' is in the notification; otherwise fetch it
  bool isLoadingRequest = false;
  String studentName = "Loading...";
  String studentNumber = "Loading...";
  String userId = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
    // If 'request' is not directly in notification, fetch it here using request_id
    // For now, assume it's present
    request = widget.notification['request'];
    if (request == null && widget.notification['request_id'] != null) {
      fetchRequest(widget.notification['request_id']);
    }
  }

  Future<void> fetchUserData() async {
    try {
      final payload = json.decode(
        utf8.decode(base64.decode(widget.token.split('.')[1]))
      );
      final userId = payload['id'];

      setState(() {
        this.userId = userId;
      });

      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['success'] == true && data['user'] != null) {
          final user = data['user'];
          setState(() {
            studentName = '${user['first_name'] ?? 'Unknown'} ${user['last_name'] ?? ''}'.trim();
            studentNumber = user['student_number'] ?? 'Unknown';
          });
        } else {
          // Handle error if needed
        }
      } else {
        // Handle error if needed
      }
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> fetchRequest(String requestId) async {
    setState(() {
      isLoadingRequest = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/requests/$requestId'), // Adjust endpoint if needed
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            request = data['request'];
          });
        }
      }
    } catch (e) {
      print('Error fetching request: $e');
    } finally {
      setState(() {
        isLoadingRequest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Updated: Parse the date and convert to local timezone
    final dateSent = widget.notification['date_sent'] != null
        ? DateFormat('MMM d, yyyy hh:mm a').format(DateTime.parse(widget.notification['date_sent']).toLocal())
        : 'Unknown';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // SIDEBAR (mirrors dashboard)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCollapsed ? 80 : 250,
            color: Colors.red[900],
            child: Column(
              children: [
                const SizedBox(height: 30),
                if (!isCollapsed)
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/Req-ITLogo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        studentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        studentNumber,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/Req-ITLogo.png',
                        width: 45,
                        height: 45,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildNavItem(Icons.home, "Dashboard"),
                        _buildNavItem(Icons.article, "Request"),
                        _buildNavItem(Icons.notifications, "Notifications"),
                        _buildNavItem(Icons.history, "History"),
                      ],
                    ),
                  ),
                ),
                _buildNavItem(Icons.logout, "Logout"),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isCollapsed ? Icons.menu_open : Icons.menu,
                                size: 30,
                                color: Colors.black87,
                              ),
                              onPressed: () {
                                setState(() {
                                  isCollapsed = !isCollapsed;
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Notification Details",
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Image.asset(
                          'assets/images/Req-ITLongLogo.png',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // NOTIFICATION DETAILS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Notification",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Message: ${widget.notification['message'] ?? 'No message'}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Date Sent: $dateSent",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // REQUEST DETAILS (mirroring dashboard's request display)
                    if (request != null) ...[
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Related Request",
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Table-like display (similar to dashboard)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: const [
                                  Expanded(flex: 2, child: Text("Reference ID", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text("Document Type", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text("Date Requested", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text("Details", style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                            const Divider(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: Text(request!['reference_id'] ?? '', style: const TextStyle(fontSize: 13))),
                                Expanded(flex: 2, child: Text((request!['documents'] as List?)?.map((d) => d['name'] as String? ?? 'Unknown').join(", ") ?? "No documents", style: const TextStyle(fontSize: 13))),
                                // Updated: Parse the request date and convert to local timezone
                                Expanded(flex: 2, child: Text(request!['request_date'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(request!['request_date']).toLocal()) : "Unknown", style: const TextStyle(fontSize: 13))),
                                Expanded(flex: 2, child: Text(request!['status'] ?? 'Unknown', style: TextStyle(fontSize: 13, color: request!['status'] == "PENDING (Payment)" ? Colors.orange : Colors.black))),
                                Expanded(flex: 2, child: Text(request!['status_details'] ?? "—", style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to tracking screen for this request
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentTrackingScreen(token: widget.token, request: request!),
                                  ),
                                );
                              },
                              child: const Text("View Full Tracking"),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isLoadingRequest) ...[
                      const Center(child: CircularProgressIndicator()),
                    ] else ...[
                      const Text("No related request found."),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SIDEBAR NAVIGATION (mirrors dashboard)
  Widget _buildNavItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          if (label == "Logout") {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          } else if (label == "Request") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentRequestForm(token: widget.token),
              ),
            );
          } else if (label == "Dashboard") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentDashboard(token: widget.token),
              ),
            );
          } else if (label == "History") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentAllRequestsScreen(token: widget.token),
              ),
            );
          } else if (label == "Notifications") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentNotificationsScreen(token: widget.token),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label clicked')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              if (!isCollapsed) ...[
                const SizedBox(width: 15),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}