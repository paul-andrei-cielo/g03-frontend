import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'registrar_dashboard.dart';
import 'staff_view_request_screen.dart';
import 'staff_all_requests_screen.dart';
import 'rfid_claim_screen.dart'; // Add this import for RfidClaimScreen

const String baseUrl = 'https://g03-backend.onrender.com';

class AllRequestsScreen extends StatefulWidget {
  final String token;
  final VoidCallback? refreshDashboard;

  const AllRequestsScreen({
    super.key,
    required this.token,
    this.refreshDashboard,
  });

  @override
  State<AllRequestsScreen> createState() => _AllRequestsScreenState();
}

class _AllRequestsScreenState extends State<AllRequestsScreen> {
  bool isCollapsed = false;
  bool isLoading = true;

  List requests = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchAllRequests();
  }

  Future<void> fetchAllRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/requests/viewrequests'),
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

            // Sort from oldest → newest
            requests.sort((a, b) => DateTime.parse(a['request_date'])
                .compareTo(DateTime.parse(b['request_date'])));

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

  List get filteredRequests {
    if (searchQuery.isEmpty) return requests;

    return requests.where((request) {
      final student = request['student_id'];
      final name = student != null
          ? '${student['first_name']} ${student['last_name']}'
          : '';

      final refId = request['reference_id'] ?? '';
      final purpose = request['purpose'] ?? '';

      return name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          refId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          purpose.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  void handleRequestUpdate() {
    fetchAllRequests();
    widget.refreshDashboard?.call();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          _buildSidebar(), // Updated to match RfidClaimScreen style
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),

                    _buildSearchBar(),

                    const SizedBox(height: 20),

                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredRequests.isEmpty
                              ? Center(
                                  child: Text(
                                    searchQuery.isEmpty
                                        ? 'No requests available'
                                        : 'No requests match your search.',
                                    style: TextStyle(
                                      fontSize: screenHeight * 0.02,
                                    ),
                                  ),
                                )
                              : _buildRequestList(),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ---------------------
  // UI Components
  // ---------------------

  Widget _buildHeader() {
    return Row(
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
              onPressed: () => setState(() => isCollapsed = !isCollapsed),
            ),
            const SizedBox(width: 10),
            const Text(
              'All Requests',
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
          height: 55,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by name, reference ID, or purpose...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onChanged: (value) => setState(() => searchQuery = value),
    );
  }

  Widget _buildRequestList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final request = filteredRequests[index];
        final student = request['student_id'];

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              student != null
                  ? '${student['first_name']} ${student['last_name']}'
                  : 'Unknown Student',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text('Reference ID: ${request['reference_id']}'),
                Text('Purpose: ${request['purpose']}'),
                Text('Total Amount: ₱${request['total_amount']}'),
                Text(
                  'Date: ${DateTime.parse(request['request_date']).toLocal().toString().split(" ")[0]}',
                ),
              ],
            ),
            trailing: Text(
              request['status'],
              style: TextStyle(
                color: Colors.red[900],
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StaffViewRequestScreen(
                    request: request,
                    token: widget.token,
                  ),
                ),
              );

              handleRequestUpdate();
            },
          ),
        );
      },
    );
  }

  // ------------------------
  // Sidebar (Updated to match RfidClaimScreen style)
  // ------------------------

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 80 : 250,
      color: Colors.red[900],
      child: Column(
        children: [
          const SizedBox(height: 30),

          // Logo
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
                ),
              ),
            ),

          const SizedBox(height: 40),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _navItem(Icons.home, "Dashboard", onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegistrarDashboard(token: widget.token),
                      ),
                    );
                  }),

                  _navItem(Icons.description, "Requests",
                      isActive: true, // ACTIVE TAB
                      onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AllRequestsScreen(token: widget.token),
                      ),
                    );
                  }),

                  _navItem(Icons.rss_feed, "RFID Claim", onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RfidClaimScreen(token: widget.token),
                      ),
                    );
                  }),

                  _navItem(Icons.person, "Profile"),
                ],
              ),
            ),
          ),

          _navItem(Icons.logout, "Logout", onTap: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(isActive ? 1 : 0.7),
                size: 26,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 15),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isActive ? 1 : 0.8),
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}