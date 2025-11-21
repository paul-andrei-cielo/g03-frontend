import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import 'student_request_form.dart';
import 'student_all_requests_screen.dart';

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

  @override
  void initState() {
    super.initState();
    fetchUserData(); 
    fetchRequests();
  }

  // In fetchUserData()
Future<void> fetchUserData() async {
  try {
    print('Fetching user data...');
    final payload = json.decode(utf8.decode(base64.decode(widget.token.split('.')[1])));
    final userId = payload['id'];
    print('Decoded user ID: $userId');

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
      // Add null check for 'success'
      if (data != null && data['success'] == true && data['user'] != null) {
        final user = data['user'];
        print('User data: $user');
        setState(() {
          studentName = '${user['first_name'] ?? 'Unknown'} ${user['last_name'] ?? ''}'.trim();  // Fallback if fields are null
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

// In fetchRequests()
Future<void> fetchRequests() async {
  try {
    print('Fetching requests...');
    final response = await http.get(
      Uri.parse('$baseUrl/requests/mine'),  // Double-check this URL
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    print('Requests response status: ${response.statusCode}');
    print('Requests response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Add null check for 'success' and 'requests'
      if (data != null && data['success'] == true && data['requests'] is List) {
        print('Requests data: ${data['requests']}');
        setState(() {
          requests = List<dynamic>.from(data['requests']);
          isLoading = false;
        });
      } else {
        print('Requests fetch failed: success=${data['success']}, message=${data['message']}');
        setError('Failed to load requests: ${data['message'] ?? 'Invalid data'}');
      }
    } else {
      setError('Failed to load requests: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in fetchRequests: $e');
    setError('Error fetching requests: $e');
  } finally {
    setState(() {
      isLoading = false;
    });
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

  Map<String, dynamic> getSummaryData() {
    if (requests.isEmpty) {  // Early return if no requests
      return {
        'activeCount': '0',
        'activeSubtitle': 'No active requests.',
        'readyCount': '0',
        'readySubtitle': 'No documents ready.',
      };
    }

    int activeCount = requests.where((r) => r['status'] != 'CLAIMED').length;
    int readyCount = requests.where((r) => r['status'] == 'FOR PICKUP').length;

    String activeSubtitle = activeCount > 0 ? "Request In Progress." : "No active requests.";
    String readySubtitle = readyCount > 0 ? "Ready for pickup." : "No documents ready.";

    if (activeCount > 0) {
      try {
        final filtered = requests.where((r) => r['status'] != 'CLAIMED' && r['request_date'] != null);
        if (filtered.isNotEmpty) {
          final latestActive = filtered.reduce((a, b) => DateTime.parse(a['request_date']).isAfter(DateTime.parse(b['request_date'])) ? a : b);
          activeSubtitle = "Latest: ${latestActive['request_date']}";
        }
      } catch (e) {
        activeSubtitle = "Request In Progress.";  // Fallback on error
      }
    }

    if (readyCount > 0) {
      try {
        final filtered = requests.where((r) => r['status'] == 'FOR PICKUP' && r['request_date'] != null);
        if (filtered.isNotEmpty) {
          final latestReady = filtered.reduce((a, b) => DateTime.parse(a['request_date']).isAfter(DateTime.parse(b['request_date'])) ? a : b);
          readySubtitle = "Latest: ${latestReady['request_date']}";
        }
      } catch (e) {
        readySubtitle = "Ready for pickup.";  // Fallback on error
      }
    }

    return {
      'activeCount': activeCount.toString(),
      'activeSubtitle': activeSubtitle,
      'readyCount': readyCount.toString(),
      'readySubtitle': readySubtitle,
    };
  }

  @override
  Widget build(BuildContext context) {
  final summary = getSummaryData();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ------------------------------------
          // SIDEBAR
          // ------------------------------------
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

          // ------------------------------------
          // MAIN CONTENT
          // ------------------------------------
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

                    // SUMMARY CARDS
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
                              "Summary Cards/Overview",
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 20),

                            Expanded(
                              child: ListView(
                                children: [
                                  _buildSummaryCard(
                                    title: "Active Request",
                                    count: summary['activeCount'],
                                    subtitle: summary['activeSubtitle'],
                                    buttonText: "View All Requests",
                                    icon: Icons.notifications,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildSummaryCard(
                                    title: "Ready for Claim",
                                    count: summary['readyCount'],
                                    subtitle: summary['readySubtitle'],
                                    buttonText: "Track Progress",
                                    icon: Icons.list_alt,
                                  ),
                                ],
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

  // ---------------------------------
  // SIDEBAR NAVIGATION
  // ---------------------------------
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

  // ---------------------------------
  // SUMMARY CARD
  // ---------------------------------
  Widget _buildSummaryCard({
    required String title,
    required String count,
    required String subtitle,
    required String buttonText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  )),
              const SizedBox(height: 6),
              Text(count,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  )),
              Text(subtitle,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.black87,
                    fontSize: 14,
                  )),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(icon, color: Colors.red[900], size: 30),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (buttonText == "View All Requests") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentAllRequestsScreen(token: widget.token),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$buttonText clicked')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
