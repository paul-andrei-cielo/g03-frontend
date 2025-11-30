import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'student_request_form.dart';
import 'edit_request_screen.dart';
import 'student_dashboard.dart';
import 'student_tracking_screen.dart';
import 'student_notifications_screen.dart';
import 'package:url_launcher/url_launcher.dart';

const String baseUrl = 'https://g03-backend.onrender.com';

class StudentAllRequestsScreen extends StatefulWidget {
  final String token;
  const StudentAllRequestsScreen({super.key, required this.token});

  @override
  State<StudentAllRequestsScreen> createState() => _StudentAllRequestsScreenState();
}

class _StudentAllRequestsScreenState extends State<StudentAllRequestsScreen> {
  bool isCollapsed = false;
  String studentName = "Loading...";
  String studentNumber = "Loading...";
  List<dynamic> requests = [];
  bool isLoading = true;
  String errorMessage = '';
  String userId = '';
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData().then((_) => fetchRequests());
    fetchUnreadNotificationCount();
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
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final user = data['user'];
          setState(() {
            studentName = '${user['first_name'] ?? 'Unknown'} ${user['last_name'] ?? ''}'.trim();
            studentNumber = user['student_number'] ?? 'Unknown';
          });
        }
      }
    } catch (e) {
      setError('Error fetching user data: $e');
    }
  }

  Future<void> fetchRequests() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/requests/$userId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['requests'] is List) {
          setState(() {
            // Removed the filter to include all requests, including completed (CLAIMED)
            requests = List<dynamic>.from(data['requests']);
          });
        } else {
          setError('Failed to load requests: ${data['message'] ?? 'Invalid data'}');
        }
      } else {
        setError('Failed to load requests: Status ${response.statusCode}');
      }
    } catch (e) {
      setError('Error fetching requests: $e');
    } finally {
      setState(() => isLoading = false);
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
    setState(() {
      errorMessage = message;
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> deleteRequest(String requestId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/requests/deleterequest/$requestId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() => requests.removeWhere((r) => r['_id'] == requestId));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request deleted successfully')));
      } else {
        setError('Failed to delete request');
      }
    } catch (e) {
      setError('Error deleting request: $e');
    }
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/requests/updatemyrequest/$requestId'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
        body: json.encode({'status': 'CANCELLED'}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request canceled successfully')));
        fetchRequests();
      } else {
        setError('Failed to cancel request');
      }
    } catch (e) {
      setError('Error canceling request: $e');
    }
  }

  Future<void> uploadProofOfPayment(String requestId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/requests/upload-proof/$requestId'));
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.files.add(await http.MultipartFile.fromPath('proof', imageFile.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proof uploaded successfully')));
        fetchRequests();
      } else {
        setError('Failed to upload proof');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
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
                        child: ClipOval(child: Image.asset('assets/images/Req-ITLogo.png', fit: BoxFit.cover)),
                      ),
                      const SizedBox(height: 10),
                      Text(studentName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.center),
                      Text(studentNumber,
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ClipOval(
                      child: Image.asset('assets/images/Req-ITLogo.png', width: 45, height: 45, fit: BoxFit.cover),
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
          // Main content
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // LEFT SIDE
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
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        // RIGHT SIDE
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
                    const SizedBox(height: 15),
                    const Text("All Requests", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)), // Updated title to reflect all requests
                    const SizedBox(height: 10),

                    // Requests List
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : requests.isEmpty
                                ? const Center(child: Text("No requests."))
                                : ListView.builder(
                                    itemCount: requests.length,
                                    itemBuilder: (context, index) {
                                      final req = requests[index];
                                      final docNames = (req['documents'] as List?)
                                              ?.map((d) => d['name'] as String? ?? 'Unknown')
                                              .join(", ") ??
                                          "No documents";
                                      final status = req['status'] ?? '';
                                      final requestId = req['reference_id'] ?? '';
                                      final internalId = req['_id'] ?? '';

                                      return GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => StudentTrackingScreen(token: widget.token, request: req),
                                          ),
                                        ),
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
                                              // Row with table headers
                                              Row(
                                                children: const [
                                                  Expanded(flex: 2, child: Text("Reference ID", style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text("Document Type", style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text("Date Requested", style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text("Remarks", style: TextStyle(fontWeight: FontWeight.bold))), // Updated header to "Remarks"
                                                  Expanded(flex: 2, child: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                                                ],
                                              ),
                                              const Divider(),

                                              // Row with data
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(flex: 2, child: Text(requestId, style: const TextStyle(fontSize: 13))),
                                                  Expanded(flex: 2, child: Text(docNames, style: const TextStyle(fontSize: 13))),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      req['request_date'] != null
                                                          ? DateFormat('MMM d, yyyy').format(DateTime.parse(req['request_date']))
                                                          : "Unknown",
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      status,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: status == "FOR PAYMENT" ? Colors.orange : Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(req['remarks'] ?? "—", style: const TextStyle(fontSize: 13)), // Updated to display remarks from staff
                                                  ),

                                                  // Actions
                                                  Expanded(
                                                    flex: 2,
                                                    child: Wrap(
                                                      spacing: 6,
                                                      runSpacing: 6,
                                                      children: [
                                                        if (status == 'FOR CLEARANCE' || status == 'FOR PAYMENT')
                                                          _actionButton("Edit", Colors.blue, () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) => EditRequestScreen(token: widget.token, request: req),
                                                              ),
                                                            ).then((_) => fetchRequests());
                                                          }),
                                                        if (status == 'FOR CLEARANCE' || status == 'FOR PAYMENT')
                                                          _actionButton("Cancel", Colors.orange, () => cancelRequest(internalId)),
                                                        _actionButton("Delete", Colors.red, () => deleteRequest(internalId)),
                                                        if (status == 'FOR PAYMENT')
                                                          _actionButton("Upload", Colors.green, () async {
                                                            const url = 'https://docs.google.com/forms/d/e/1FAIpQLSfmMOI9nncHfwbY0Cxjt4p3XFBSYN-0ly4RV8Wiwjs4kruU1Q/viewform';
                                                            try {
                                                              final uri = Uri.parse(url);
                                                              if (await canLaunchUrl(uri)) {
                                                                await launchUrl(uri, mode: LaunchMode.externalApplication); 
                                                              } else {
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  const SnackBar(content: Text('Could not launch the form. Please check the URL.')),
                                                                );
                                                              }
                                                            } catch (e) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(content: Text('Error launching form: $e')),
                                                              );
                                                            }
                                                          }),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
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

  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
        child: Text(label, style: const TextStyle(fontSize: 12)),
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
            Navigator.push(context, MaterialPageRoute(builder: (_) => StudentRequestForm(token: widget.token)));
          } else if (label == "Dashboard") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDashboard(token: widget.token)));
          } else if (label == "History") {
            fetchRequests();
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
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              if (!isCollapsed) ...[
                const SizedBox(width: 15),
                Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}