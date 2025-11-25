import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'package:intl/intl.dart';
import 'dart:convert'; 
import 'student_request_form.dart';
import 'student_all_requests_screen.dart';
import 'student_tracking_screen.dart';
import 'student_notifications_screen.dart'; // Add this import

const String baseUrl = 'https://g03-backend.onrender.com';

class StudentDashboard extends StatefulWidget {
  final String token;
  const StudentDashboard({super.key, required this.token});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool isCollapsed = false;

  String studentName = "Loading...";
  String studentNumber = "Loading...";
  List<dynamic> requests = [];
  bool isLoading = true;
  String errorMessage = '';
  String userId = '';
  int notificationCount = 0; // For notification badge

  @override
  void initState() {
    super.initState();
    fetchUserData().then((_) {
      fetchRequests();
      fetchNotificationCount();
    });
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
          setError('Failed to load user data: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        setError('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      setError('Error fetching user data: $e');
    }
  }

  Future<void> fetchRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/requests/$userId'), 
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['success'] == true && data['requests'] is List) {
          setState(() {
            requests = List<dynamic>.from(data['requests']);
          });
        } else {
          setError('Failed to load requests: ${data['message'] ?? 'Invalid data'}');
        }
      } else {
        setError('Failed to load requests: ${response.statusCode}');
      }
    } catch (e) {
      setError('Error fetching requests: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchNotificationCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/view'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['success'] == true && data['notifications'] is List) {
          setState(() {
            notificationCount = data['notifications'].length;
          });
        }
      }
    } catch (e) {
      print('Error fetching notification count: $e');
    }
  }

  void setError(String message) {
    setState(() {
      errorMessage = message;
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<dynamic> getActiveRequests() {
    List<dynamic> active = requests.where((r) => 
      r['status'] != 'CLAIMED' && r['status'] != 'CANCELLED' && r['status'] != 'REJECTED'
    ).toList();
    
    active.sort((a, b) {
      DateTime dateA = DateTime.tryParse(a['request_date'] ?? '') ?? DateTime(1900);
      DateTime dateB = DateTime.tryParse(b['request_date'] ?? '') ?? DateTime(1900);
      return dateB.compareTo(dateA);
    });
    
    return active;
  }

  @override
  Widget build(BuildContext context) {
    final activeRequests = getActiveRequests();

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
                        _buildNavItem(Icons.search, "Tracking"),
                        _buildNavItem(Icons.history, "History"),
                        _buildNavItem(Icons.person, "Profile"),
                        _buildNavItem(Icons.help, "Help"),
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
                            Text(
                              "Hello, ${studentName.split(' ').first}!",
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications, size: 30, color: Colors.black87),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StudentNotificationsScreen(token: widget.token),
                                      ),
                                    ).then((_) => fetchNotificationCount());
                                  },
                                ),
                                if (notificationCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.red,
                                      child: Text(
                                        notificationCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Image.asset(
                              'assets/images/Req-ITLongLogo.png',
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),
                    const Text(
                      "Need to Request a Document?",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentRequestForm(token: widget.token),
                          ),
                        );
                        if (result == true) {
                          fetchRequests();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "+ Request New Document",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Expanded(
                      child: Container(
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
                              "Recent Active Requests",
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : activeRequests.isEmpty
                                      ? const Center(child: Text("No active requests."))
                                      : ListView.builder(
                                          itemCount: activeRequests.length,
                                          itemBuilder: (context, index) {
                                            final req = activeRequests[index];
                                            final docNames = (req['documents'] as List?)?.map((d) => d['name'] as String? ?? 'Unknown').join(", ") ?? "No documents";
                                            final status = req['status'] ?? 'Unknown';
                                            final requestId = req['reference_id'] ?? '';
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => StudentTrackingScreen(token: widget.token, request: req),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 15),
                                                padding: const EdgeInsets.all(15),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.grey.shade300),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
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
                                                        Expanded(flex: 2, child: Text(requestId, style: const TextStyle(fontSize: 13))),
                                                        Expanded(flex: 2, child: Text(docNames, style: const TextStyle(fontSize: 13))),
                                                        Expanded(flex: 2, child: Text(req['request_date'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(req['request_date'])) : "Unknown", style: const TextStyle(fontSize: 13))),
                                                        Expanded(flex: 2, child: Text(status, style: TextStyle(fontSize: 13, color: status == "PENDING (Payment)" ? Colors.orange : Colors.black))),
                                                        Expanded(flex: 2, child: Text(req['status_details'] ?? "—", style: const TextStyle(fontSize: 13))),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
            fetchRequests();
          } else if (label == "History") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentAllRequestsScreen(token: widget.token),
              ),
            );
          } else if (label == "Notifications") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentNotificationsScreen(token: widget.token),
              ),
            ).then((_) => fetchNotificationCount());
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
