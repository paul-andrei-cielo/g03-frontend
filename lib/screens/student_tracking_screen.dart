import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'student_request_form.dart';
import 'student_all_requests_screen.dart';
import 'student_notifications_screen.dart'; // Added import for notifications screen
import 'dart:convert'; // For json, utf8, base64
import 'package:http/http.dart' as http; // For http

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
  int notificationCount = 0; // Added for notification count

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchUnreadNotificationCount(); // Added to fetch notification count
  }

  Future<void> fetchUserData() async {
    try {
      final payload = json.decode(utf8.decode(base64.decode(widget.token.split('.')[1])));
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
          setError('Failed to load user data: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        setError('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      setError('Error fetching user data: $e');
    }
  }

  Future<void> fetchUnreadNotificationCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['success'] == true) {
          setState(() {
            notificationCount = data['unreadCount'] ?? 0;
          });
        } else {
          // Optional: handle error silently or log
        }
      } else {
        // Optional: handle error silently or log
      }
    } catch (e) {
      // Optional: handle error silently or log
    }
  }

  void setError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ────────────────────────────────────────────────
  // STATUS METADATA
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

  static const List<String> statusOrder = [
    'FOR CLEARANCE',
    'FOR PAYMENT',
    'PROCESSING',
    'FOR PICKUP',
    'CLAIMED',
  ];

  // ────────────────────────────────────────────────
  // BUILD TIMELINE
  // ────────────────────────────────────────────────
  List<Map<String, dynamic>> _buildTimeline() {
    final currentStatus = widget.request['status']?.toUpperCase() ?? 'FOR CLEARANCE';
    final requestDate = widget.request['request_date'];

    List<Map<String, dynamic>> timeline = [];
    int lastIndex = 0;

    if (currentStatus == 'CANCELLED' || currentStatus == 'REJECTED') {
      lastIndex = statusOrder.length - 1;
      for (int i = 0; i <= lastIndex; i++) {
        final status = statusOrder[i];
        final meta = statusMetadata[status]!;
        timeline.add({
          'status': _formatStatus(status),
          'details': '', // no subtitle
          'timestamp': _getTimestamp(i, requestDate),
          'color': meta['color'],
          'upload': false, // upload button should never show for past statuses
        });
      }
      final meta = statusMetadata[currentStatus]!;
      timeline.add({
        'status': _formatStatus(currentStatus),
        'details': meta['details'],
        'timestamp': DateFormat('MM/dd/yyyy\nHH:mm:ss').format(DateTime.now()),
        'color': meta['color'],
        'upload': false,
      });
    } else {
      final currentIndex = statusOrder.indexOf(currentStatus);
      lastIndex = currentIndex == -1 ? 0 : currentIndex;

      for (int i = 0; i <= lastIndex; i++) {
        final status = statusOrder[i];
        final meta = statusMetadata[status]!;

        // Upload button logic: Only show for FOR PAYMENT if it is the latest status
        bool showUpload = meta['upload'] && i == lastIndex;

        timeline.add({
          'status': _formatStatus(status),
          'details': i == lastIndex ? meta['details'] : '',
          'timestamp': _getTimestamp(i, requestDate),
          'color': meta['color'],
          'upload': showUpload,
        });
      }
    }

    return timeline;
  }

  String _formatStatus(String status) {
    return status.split(' ').map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  String _getTimestamp(int index, dynamic requestDate) {
    if (requestDate != null) {
      final date = requestDate is DateTime ? requestDate : DateTime.parse(requestDate);
      return DateFormat('MM/dd/yyyy\nHH:mm:ss').format(date.add(Duration(hours: index))); // stagger optional
    }
    return 'Pending';
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentRequestForm(token: widget.token)));
          } else if (label == "Dashboard") {
            Navigator.pop(context);
          } else if (label == "History") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => StudentAllRequestsScreen(token: widget.token)));
          } else if (label == "Notifications") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentNotificationsScreen(token: widget.token),
              ),
            ).then((_) {
              // Refresh count when returning from notifications screen
              fetchUnreadNotificationCount();
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label clicked')));
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

  void _cancelRequest() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Request"),
        content: const Text("Are you sure you want to cancel this request?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request cancelled.")));
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reference = widget.request['reference_id'] ?? "#68ebba15";
    final document = widget.request['documents'] != null && (widget.request['documents'] as List).isNotEmpty
        ? (widget.request['documents'][0]['name'] ?? "Document")
        : "Document";

    final timeline = _buildTimeline();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // SIDEBAR
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
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: ClipOval(child: Image.asset('assets/images/Req-ITLogo.png')),
                      ),
                      const SizedBox(height: 10),
                      Text(studentName,
                          style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.center),
                      Text(studentNumber,
                          style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat', fontSize: 14)),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Image.asset('assets/images/Req-ITLogo.png', width: 45, height: 45),
                  ),
                const SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildNavItem(Icons.home, "Dashboard"),
                        _buildNavItem(Icons.article, "Request"),
                        _buildNavItem(Icons.notifications, "Notifications"), // Mirrored nav items
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
                              icon: Icon(isCollapsed ? Icons.menu_open : Icons.menu, size: 30, color: Colors.black87),
                              onPressed: () => setState(() => isCollapsed = !isCollapsed),
                            ),
                            const SizedBox(width: 10),
                            Text("Hello, ${studentName.split(' ').first}!",
                                style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 28)),
                          ],
                        ),
                        // RIGHT SIDE - Added notification bell with badge for uniformity
                        Row(
                          children: [
                            // Notification Bell with Badge
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StudentNotificationsScreen(token: widget.token),
                                  ),
                                ).then((_) {
                                  // Refresh count when returning
                                  fetchUnreadNotificationCount();
                                });
                              },
                              child: Stack(
                                children: [
                                  Icon(
                                    Icons.notifications,
                                    size: 30,
                                    color: Colors.black87,
                                  ),
                                  if (notificationCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          notificationCount > 99 ? '99+' : notificationCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Image.asset(
                              'assets/images/Req-ITLongLogo.png',
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Reference $reference | $document",
                            style: const TextStyle(fontSize: 20, fontFamily: 'Montserrat', fontWeight: FontWeight.w700)),
                        if (['FOR CLEARANCE', 'FOR PAYMENT'].contains(widget.request['status']?.toUpperCase()))
                          ElevatedButton(
                            onPressed: _cancelRequest,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                            child: const Text("Cancel Request", style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: Colors.white)),
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
                                SizedBox(
                                  width: 100,
                                  child: Text(item["timestamp"],
                                      textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13)),
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  children: [
                                    Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: item["color"])),
                                    if (index != timeline.length - 1)
                                      Container(width: 2, height: 60, color: Colors.grey.shade400),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item["status"],
                                          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 17, color: item["color"])),
                                      const SizedBox(height: 6),
                                      if (item["details"].isNotEmpty)
                                        Text(item["details"], style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: Colors.black87)),
                                      if (hasUpload)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 10),
                                          child: ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.grey.shade300,
                                                foregroundColor: Colors.black,
                                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                                            child: const Text("Upload",
                                                style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
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