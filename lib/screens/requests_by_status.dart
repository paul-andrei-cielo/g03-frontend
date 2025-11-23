import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'registrar_dashboard.dart'; // Dashboard import
import 'staff_view_request_screen.dart'; // View request screen
import 'staff_all_requests_screen.dart'; // All requests screen

const String baseUrl = 'https://g03-backend.onrender.com';

class RequestsByStatusScreen extends StatefulWidget {
  final String status;
  final String token;
  final VoidCallback? refreshDashboard; // Added callback

  const RequestsByStatusScreen({
    super.key,
    required this.status,
    required this.token,
    this.refreshDashboard,
  });

  @override
  State<RequestsByStatusScreen> createState() => _RequestsByStatusScreenState();
}

class _RequestsByStatusScreenState extends State<RequestsByStatusScreen> {
  bool isCollapsed = false;
  bool isLoading = true;
  List requests = [];
  String searchQuery = ''; // Added for search functionality

  @override
  void initState() {
    super.initState();
    fetchRequestsByStatus();
  }

  Future<void> fetchRequestsByStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/requests/requestsbystatus?status=${Uri.encodeComponent(widget.status)}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            requests = data['requests'];
            // Sort requests from oldest to newest by request_date
            requests.sort((a, b) => DateTime.parse(a['request_date']).compareTo(DateTime.parse(b['request_date'])));
            isLoading = false;
          });
        } else {
          print("API returned failure: ${data['message']}");
          setState(() => isLoading = false);
        }
      } else {
        print("Failed to fetch: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching requests: $e");
      setState(() => isLoading = false);
    }
  }

  // Computed property for filtered requests
  List get filteredRequests {
    if (searchQuery.isEmpty) return requests;
    return requests.where((request) {
      final student = request['student_id'];
      final name = student != null ? '${student['first_name']} ${student['last_name']}' : '';
      final refId = request['reference_id'] ?? '';
      final purpose = request['purpose'] ?? '';
      return name.toLowerCase().contains(searchQuery.toLowerCase()) ||
             refId.toLowerCase().contains(searchQuery.toLowerCase()) ||
             purpose.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  void handleRequestUpdate() {
    fetchRequestsByStatus(); // Refresh local list
    widget.refreshDashboard?.call(); // Refresh dashboard counts
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
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
                      const SizedBox(height: 15),
                      const Text(
                        "Req-IT",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
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
                        _buildNavItem(Icons.home, "Dashboard", onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RegistrarDashboard(token: widget.token),
                            ),
                          );
                        }),
                        _buildNavItem(Icons.description, "Requests", onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AllRequestsScreen(token: widget.token),
                            ),
                          );
                        }),
                        _buildNavItem(Icons.person, "Profile"),
                      ],
                    ),
                  ),
                ),
                _buildNavItem(Icons.logout, "Logout", onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                }),
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
                              'Requests: ${widget.status}',
                              style: const TextStyle(
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
                          height: 55,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by student name, reference ID, or purpose...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    // List of requests
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredRequests.isEmpty
                              ? Center(
                                  child: Text(
                                    searchQuery.isEmpty
                                        ? 'No requests for "${widget.status}"'
                                        : 'No requests match your search.',
                                    style:
                                        TextStyle(fontSize: screenHeight * 0.02),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredRequests.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final request = filteredRequests[index];
                                    final student = request['student_id'];
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 3,
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(16),
                                        title: Text(
                                          student != null
                                              ? '${student['first_name']} ${student['last_name']}'
                                              : 'Unknown Student',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 5),
                                            Text(
                                                'Reference ID: ${request['reference_id']}'),
                                            Text('Purpose: ${request['purpose']}'),
                                            Text(
                                                'Total Amount: ₱${request['total_amount']}'),
                                            Text(
                                                'Date: ${DateTime.parse(request['request_date']).toLocal().toString().split(' ')[0]}'),
                                          ],
                                        ),
                                        trailing: Text(
                                          request['status'],
                                          style: TextStyle(
                                              color: Colors.red[900],
                                              fontWeight: FontWeight.bold),
                                        ),
                                        onTap: () async {
                                          // Navigate to view screen and refresh on return
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  StaffViewRequestScreen(
                                                request: request,
                                                token: widget.token,
                                              ),
                                            ),
                                          );
                                          handleRequestUpdate(); // Refresh after returning
                                        },
                                      ),
                                    );
                                  },
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

  Widget _buildNavItem(IconData icon, String label, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label clicked')),
              );
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