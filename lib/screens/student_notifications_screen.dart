import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'student_request_form.dart';
import 'student_all_requests_screen.dart';
import 'student_tracking_screen.dart';
import 'student_dashboard.dart';  // For navigation back to dashboard
import 'student_notification_detail_screen.dart';  // Add this import for the new detail screen

const String baseUrl = 'https://g03-backend.onrender.com';

class StudentNotificationsScreen extends StatefulWidget {
  final String token;
  const StudentNotificationsScreen({super.key, required this.token});

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  bool isCollapsed = false;
  List<dynamic> notifications = [];
  bool isLoading = true;
  String errorMessage = '';
  String studentName = "Loading...";
  String studentNumber = "Loading...";
  String userId = '';

  @override
  void initState() {
    super.initState();
    fetchUserData().then((_) {
      fetchNotifications();
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

  Future<void> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/view'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['success'] == true && data['notifications'] is List) {
          setState(() {
            notifications = List<dynamic>.from(data['notifications']);
            isLoading = false;
          });
        } else {
          setError('Invalid response: ${data}');
        }
      } else {
        setError('Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setError('Error: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read/$notificationId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = notifications.indexWhere((notif) => notif['_id'] == notificationId);
          if (index != -1) {
            notifications[index]['read'] = true;
          }
        });
      } else {
        final responseData = json.decode(response.body);
        if (responseData['message'] == 'Notification not found or already read.') {
          setState(() {
            final index = notifications.indexWhere((notif) => notif['_id'] == notificationId);
            if (index != -1) {
              notifications[index]['read'] = true;
            }
          });
        } else {
          print('Failed to mark as read: ${response.body}');
          setState(() {
            final index = notifications.indexWhere((notif) => notif['_id'] == notificationId);
            if (index != -1) {
              notifications[index]['read'] = true;  
            }
          });
        }
      }
    } catch (e) {
      print('Error marking as read: $e');
      setState(() {
        final index = notifications.indexWhere((notif) => notif['_id'] == notificationId);
        if (index != -1) {
          notifications[index]['read'] = true;  
        }
      });
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/delete/$notificationId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications.removeWhere((notif) => notif['_id'] == notificationId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted successfully.')),
        );
      } else {
        setError('Failed to delete notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setError('Error deleting notification: $e');
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

  @override
  Widget build(BuildContext context) {
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
                              "Notifications",
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

                    // NOTIFICATIONS LIST
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
                            Expanded(
                              child: isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : notifications.isEmpty
                                      ? const Center(child: Text("No notifications."))
                                      : ListView.builder(
                                          itemCount: notifications.length,
                                          itemBuilder: (context, index) {
                                            final notif = notifications[index];
                                            final message = notif['message'] ?? 'No message';
                                            final dateSent = notif['date_sent'] != null
                                                ? (() {
                                                    try {
                                                      DateTime parsedDate = DateTime.parse(notif['date_sent']);
                                                      DateTime localDate = parsedDate.toLocal();
                                                      return DateFormat('MMM d, yyyy hh:mm a').format(localDate);
                                                    } catch (e) {
                                                      return 'Invalid date';
                                                    }
                                                  })()
                                                : 'Unknown';
                                            final isRead = notif['read'] ?? false;
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 15),
                                              padding: const EdgeInsets.all(15),
                                              decoration: BoxDecoration(
                                                color: isRead ? Colors.grey.shade100 : Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: isRead ? Colors.grey.shade400 : Colors.grey.shade300),
                                              ),
                                              child: Row(
                                                children: [
                                                  if (!isRead)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    )
                                                  else
                                                    const SizedBox(width: 8),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: MouseRegion(
                                                      cursor: SystemMouseCursors.click,
                                                      child: GestureDetector(
                                                        onTap: () async {
                                                          if (!isRead) {
                                                            final notificationId = notif['_id'];
                                                            await markAsRead(notificationId);
                                                          }
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => StudentNotificationDetailScreen(
                                                                notification: notif,
                                                                token: widget.token,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              message,
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontFamily: 'Montserrat',
                                                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 10),
                                                            Text(
                                                              dateSent,
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey,
                                                                fontFamily: 'Montserrat',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () async {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: const Text('Delete Notification'),
                                                          content: const Text('Are you sure you want to delete this notification?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.of(context).pop(false),
                                                              child: const Text('Cancel'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () => Navigator.of(context).pop(true),
                                                              child: const Text('Delete'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirm == true) {
                                                        await deleteNotification(notif['_id']);
                                                      }
                                                    },
                                                  ),
                                                ],
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
            // Already on this screen, do nothing or refresh
            fetchNotifications();
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