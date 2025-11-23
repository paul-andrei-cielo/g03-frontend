import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'student_request_form.dart';
import 'student_all_requests_screen.dart';
import 'dart:convert';  // Added for json, utf8, base64
import 'package:http/http.dart' as http;  // Added for http

const baseUrl = 'https://g03-backend.onrender.com';

class StudentTrackingScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> request; // pass selected request here

  const StudentTrackingScreen({
    super.key,
    required this.token,
    required this.request,
  });

  @override
  State<StudentTrackingScreen> createState() => _StudentTrackingScreenState();
}

class _StudentTrackingScreenState extends State<StudentTrackingScreen> {
  bool isCollapsed = false;

  String studentName = "Loading...";
  String studentNumber = "Loading...";
  String userId = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      print('Fetching user data...');
      final payload = json.decode(utf8.decode(base64.decode(widget.token.split('.')[1])));
      final userId = payload['id'];
      print('Decoded user ID: $userId');

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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['success'] == true && data['user'] != null) {
          final user = data['user'];
          print('User data: $user');
          setState(() {
            studentName = '${user['first_name'] ?? 'Unknown'} ${user['last_name'] ?? ''}'.trim();
            studentNumber = user['student_number'] ?? 'Unknown';
          });
        } else {
          print('User data fetch failed: success=${data['success']}, message=${data['message']}');
          setError('Failed to load user data: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        setError('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchUserData: $e');
      setError('Error fetching user data: $e');
    }
  }

  void setError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ────────────────────────────────────────────────
  // STATUS METADATA (constant, based on your hardcoded data)
  // ────────────────────────────────────────────────
  static const Map<String, Map<String, dynamic>> statusMetadata = {
    'FOR CLEARANCE': {
      'details': 'Clearance verification is ongoing.',
      'color': Color(0xFFF4C542),
      'upload': false,
    },
    'FOR PAYMENT': {
      'details': 'Your clearance has been verified. Please upload your proof of payment.',
      'color': Color(0xFFF28C28),
      'upload': true,
    },
    'PROCESSING': {
      'details': 'Your proof of payment has been verified. Please stand by while your document is being prepared.',
      'color': Color(0xFF3A82F7),
      'upload': false,
    },
    'FOR PICKUP': {
      'details': 'Your document is ready to be picked up. You may claim it at the registrar’s office.\nImportant: Please bring your student ID for RFID authentication.',
      'color': Color(0xFF8A4FFF),
      'upload': false,
    },
    'CLAIMED': {
      'details': 'You have successfully claimed your document. Thank you.',
      'color': Color(0xFF4CAF50),
      'upload': false,
    },
    'CANCELLED': {
      'details': 'This request has been cancelled.',
      'color': Colors.grey,
      'upload': false,
    },
    'REJECTED': {
      'details': 'This request has been rejected. Please check the remarks for more details.',
      'color': Colors.red,
      'upload': false,
    },
  };

  // ────────────────────────────────────────────────
  // STATUS ORDER (for progression)
  // ────────────────────────────────────────────────
  static const List<String> statusOrder = [
    'FOR CLEARANCE',
    'FOR PAYMENT',
    'PROCESSING',
    'FOR PICKUP',
    'CLAIMED',
  ];

  // ────────────────────────────────────────────────
  // BUILD DYNAMIC TIMELINE BASED ON REQUEST STATUS
  // ────────────────────────────────────────────────
  List<Map<String, dynamic>> _buildTimeline() {
    final currentStatus = widget.request['status']?.toUpperCase() ?? 'FOR CLEARANCE';
    final requestDate = widget.request['request_date']; // Assuming this is a DateTime or ISO string

    List<Map<String, dynamic>> timeline = [];

    // If status is CANCELLED or REJECTED, show progression up to the last valid status, then add the special status
    if (currentStatus == 'CANCELLED' || currentStatus == 'REJECTED') {
      final lastValidIndex = statusOrder.length - 1; // Assume CLAIMED is the last before special
      for (int i = 0; i <= lastValidIndex; i++) {
        final status = statusOrder[i];
        final meta = statusMetadata[status]!;
        timeline.add({
          'status': _formatStatus(status),
          'details': meta['details'],
          'timestamp': _getTimestamp(i, requestDate),
          'color': meta['color'],
          'upload': meta['upload'],
        });
      }
      // Add the special status
      final meta = statusMetadata[currentStatus]!;
      timeline.add({
        'status': _formatStatus(currentStatus),
        'details': meta['details'],
        'timestamp': DateFormat('MM/dd/yyyy\nHH:mm:ss').format(DateTime.now()), // Use current time for cancellation/rejection
        'color': meta['color'],
        'upload': meta['upload'],
      });
    } else {
      // Normal progression: Show statuses up to the current one
      final currentIndex = statusOrder.indexOf(currentStatus);
      if (currentIndex == -1) {
        // Fallback: Show only FOR CLEARANCE if status is invalid
        final status = statusOrder[0];
        final meta = statusMetadata[status]!;
        timeline.add({
          'status': _formatStatus(status),
          'details': meta['details'],
          'timestamp': _getTimestamp(0, requestDate),
          'color': meta['color'],
          'upload': meta['upload'],
        });
      } else {
        for (int i = 0; i <= currentIndex; i++) {
          final status = statusOrder[i];
          final meta = statusMetadata[status]!;
          timeline.add({
            'status': _formatStatus(status),
            'details': meta['details'],
            'timestamp': _getTimestamp(i, requestDate),
            'color': meta['color'],
            'upload': meta['upload'],
          });
        }
      }
    }

    return timeline;
  }

  // Helper: Format status to title case (e.g., "FOR CLEARANCE" -> "For Clearance")
  String _formatStatus(String status) {
    return status.split(' ').map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  // Helper: Get timestamp for a status index
  String _getTimestamp(int index, dynamic requestDate) {
    if (index == 0 && requestDate != null) {
      // For the first status, use request_date
      final date = requestDate is DateTime ? requestDate : DateTime.parse(requestDate);
      return DateFormat('MM/dd/yyyy\nHH:mm:ss').format(date);
    }
    // For others, use a placeholder (since no real timestamps exist)
    return 'Pending'; // Or use DateTime.now() if you want current time
  }

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
            Navigator.pop(context); // Assuming dashboard is the previous screen
          } else if (label == "History") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentAllRequestsScreen(token: widget.token),
              ),
            );
          } else if (label == "Tracking") {
            // Already on tracking, maybe do nothing or refresh
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Already on Tracking')),
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

  // Cancel Request Dialog (unchanged)
  void _cancelRequest() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Request"),
        content: const Text("Are you sure you want to cancel this request?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Request cancelled.")),
              );
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reference = widget.request['reference_id'] ?? "#68ebba15"; // Updated to match model
    final document = widget.request['documents'] != null && (widget.request['documents'] as List).isNotEmpty
        ? (widget.request['documents'][0]['name'] ?? "Document") // Assume first document
        : "Document";

    final timeline = _buildTimeline(); // Dynamically build timeline

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ───────────────────────────────────────────────
          // SIDEBAR — MATCHED FROM DASHBOARD (unchanged)
          // ───────────────────────────────────────────────
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
                          child: Image.asset('assets/images/Req-ITLogo.png'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        studentName,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        studentNumber,
                        style: TextStyle(
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
                    child: Image.asset('assets/images/Req-ITLogo.png',
                        width: 45, height: 45),
                  ),
                const SizedBox(height: 40),

                // NAV
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildNavItem(Icons.home, "Dashboard"),
                        _buildNavItem(Icons.article, "Request"),
                        _buildNavItem(Icons.search, "Tracking"),
                        _buildNavItem(Icons.history, "History"),
                        _buildNavItem(Icons.person, "Profile"),
                        _buildNavItem(Icons.help, "Help"),
                      ],
                    ),
                  ),
                ),
                _buildNavItem(Icons.logout, "Logout"),  // Removed 'const'
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ───────────────────────────────────────────────
          // MAIN CONTENT (updated to use dynamic timeline)
          // ───────────────────────────────────────────────
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER (unchanged)
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
                                setState(() => isCollapsed = !isCollapsed);
                              },
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Hello, ${studentName.split(' ').first}!",
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ],
                        ),
                        Image.asset(
                          'assets/images/Req-ITLongLogo.png',
                          height: 60,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // REFERENCE TITLE + CANCEL BUTTON (unchanged)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Reference $reference | $document",
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _cancelRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Cancel Request",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView.builder(
                        itemCount: timeline.length,
                        itemBuilder: (context, index) {
                          final item = timeline[index];
                          final bool hasUpload = item["upload"] == true;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 25),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // DATE/TIME
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    item["timestamp"],
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 20),

                                // TIMELINE DOT + LINE
                                Column(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: item["color"],
                                      ),
                                    ),
                                    if (index != timeline.length - 1)
                                      Container(
                                        width: 2,
                                        height: 60,
                                        color: Colors.grey.shade400,
                                      ),
                                  ],
                                ),

                                const SizedBox(width: 20),

                                // STATUS + DETAILS
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item["status"],
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: item["color"],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item["details"],
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),

                                      // UPLOAD BUTTON
                                      if (hasUpload)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.grey.shade300,
                                              foregroundColor: Colors.black,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 22,
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                              ),
                                            ),
                                            child: const Text(
                                              "Upload",
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}