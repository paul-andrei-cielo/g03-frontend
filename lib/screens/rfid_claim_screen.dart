import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'registrar_dashboard.dart';
import 'staff_all_requests_screen.dart';
import 'registrar_profile_screen.dart';

const String baseUrl = 'https://g03-backend.onrender.com';

class RfidClaimScreen extends StatefulWidget {
  final String token;
  const RfidClaimScreen({super.key, required this.token});

  @override
  State<RfidClaimScreen> createState() => _RfidClaimScreenState();
}

class _RfidClaimScreenState extends State<RfidClaimScreen> {
  bool isCollapsed = false;

  final TextEditingController rfidController = TextEditingController();
  final FocusNode rfidFocus = FocusNode();
  final TextEditingController searchController = TextEditingController();

  Map<String, dynamic>? requestData;
  List requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllRequests();
    Future.delayed(Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(rfidFocus);
    });
  }

  @override
  void dispose() {
    rfidController.dispose();
    rfidFocus.dispose();
    searchController.dispose();
    super.dispose();
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
            requests = data['requests'] ?? [];
            // Sort requests from oldest to newest by request_date
            requests.sort((a, b) {
              final dateA = a['request_date'] ?? '';
              final dateB = b['request_date'] ?? '';
              return dateA.compareTo(dateB);
            });
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

  void handleScan(String code) {
    if (requestData != null) {
      // RFID scan for claiming: Compare scanned code to the student's RFID tag
      final studentRfid = requestData!['student_id']['rfid_tag'];
      if (studentRfid != null && studentRfid == code && requestData!['status'] == 'FOR PICKUP') {
        // Valid match: Proceed to claim
        confirmClaim();
      } else {
        // Invalid RFID or request not ready
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid RFID tag or request not ready for pickup')),
        );
      }
    } else {
      // No request loaded: Do not attempt to load via RFID (rely on search)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No request loaded. Use search to load a request first.')),
      );
    }
    rfidController.clear();
    FocusScope.of(context).requestFocus(rfidFocus);
  }

  void handleSearch(String query) {
    if (query.isNotEmpty) {
      final matchingRequest = requests.firstWhere(
        (r) => r['reference_id'] == query && r['status'] == 'FOR PICKUP',
        orElse: () => null,
      );
      if (matchingRequest != null) {
        setState(() {
          requestData = matchingRequest;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No matching request found for reference ID: $query')),
        );
      }
    }
    searchController.clear();
  }

  Future<void> confirmClaim() async {
    if (requestData == null) return;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/updaterequest/${requestData!['id']}'),  // Fixed URL to match backend
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': 'CLAIMED'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          requestData = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document claimed successfully')),
        );
        fetchAllRequests();
      } else {
        print("Failed to claim: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to claim document: ${response.body}')),
        );
      }
    } catch (e) {
      print("Error claiming: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error claiming document')),
      );
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case "FOR CLEARANCE":
        return Color(0xFFF4C542);
      case "FOR PAYMENT":
        return Color(0xFFF28C28);
      case "PROCESSING":
        return Color(0xFF3A82F7);
      case "FOR PICKUP":
        return Color(0xFF8A4FFF);
      case "CLAIMED":
        return Color(0xFF4CAF50);
      case "CANCELLED":
        return Color(0xFF9E9E9E);
      case "REJECTED":
        return Color(0xFFE53935);
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // =============================
          // COLLAPSIBLE SIDEBAR
          // =============================
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
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
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
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
                        _navItem(Icons.home, "Dashboard", onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RegistrarDashboard(token: widget.token),
                            ),
                          );
                        }),
                        _navItem(Icons.description, "Requests", onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AllRequestsScreen(token: widget.token),
                            ),
                          );
                        }),
                        _navItem(Icons.rss_feed, "RFID Claim", isActive: true),
                        _navItem(Icons.person, "Profile", onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RegistrarProfileScreen(token: widget.token),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                _navItem(Icons.logout, "Logout", onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // =============================
          // MAIN CONTENT
          // =============================
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(25),
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
                            SizedBox(width: 10),
                            Text(
                              "RFID Claiming",
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Image.asset(
                          'assets/images/Req-ITLongLogo.png',
                          height: 55,
                        )
                      ],
                    ),

                    SizedBox(height: 20),

                    // SEARCH BAR
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by reference ID...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onSubmitted: handleSearch,
                    ),

                    SizedBox(height: 20),

                    // CONDITIONAL LAYOUT: REQUEST CARD AND RFID SCAN
                    if (requestData != null)
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // REQUEST CARD (LEFT COLUMN)
                            Expanded(
                              child: _buildClaimCard(requestData!),
                            ),
                            SizedBox(width: 20),
                            // RFID SCAN BOX (RIGHT COLUMN)
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Scan RFID to Claim Document",
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Icon(Icons.contactless,
                                        size: 80, color: Colors.red),
                                    SizedBox(height: 20),
                                    Text(
                                      "Tap your school ID on the RFID scanner.",
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    SizedBox(height: 30),
                                    // Hidden input
                                    Opacity(
                                      opacity: 0,
                                      child: TextField(
                                        controller: rfidController,
                                        focusNode: rfidFocus,
                                        autofocus: true,
                                        onSubmitted: handleScan,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // RFID SCAN BOX (FULL WIDTH WHEN NO REQUEST)
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Scan RFID to Claim Document",
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 20),
                              Icon(Icons.contactless,
                                  size: 80, color: Colors.red),
                              SizedBox(height: 20),
                              Text(
                                "Tap your school ID on the RFID scanner.",
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 30),
                              // Hidden input
                              Opacity(
                                opacity: 0,
                                child: TextField(
                                  controller: rfidController,
                                  focusNode: rfidFocus,
                                  autofocus: true,
                                  onSubmitted: handleScan,
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

  Widget _navItem(IconData icon, String label,
      {bool isActive = false, VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            children: [
              Icon(icon,
                  color: Colors.white.withOpacity(isActive ? 1 : 0.7),
                  size: 26),
              if (!isCollapsed) ...[
                SizedBox(width: 15),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isActive ? 1 : 0.8),
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClaimCard(Map<String, dynamic> data) {
    final student = data['student_id'] as Map<String, dynamic>?;
    final studentName = (student != null
            ? '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'
            : 'Unknown Student')
        .trim();

    final reference = data['reference_id'] ?? 'N/A';
    final status = data['status'] ?? 'UNKNOWN';
    final dateRequested = data['request_date'] != null
        ? DateTime.tryParse(data['request_date'])?.toLocal().toString().split(' ')[0] ??
            'Unknown Date'
        : 'Unknown Date';

    final documents = data['documents'] as List<dynamic>? ?? [];
    final color = getStatusColor(status);

    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Colors.black12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reference,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 10),
          Text(
            studentName,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 15),
          if (documents.isNotEmpty) ...[
            Text(
              "Documents Requested:",
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 10),
            ...documents.map((doc) => Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text(
                "• ${doc['name'] ?? 'Unknown Document'} (${doc['copies'] ?? 0}x)",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            )),
            SizedBox(height: 15),
          ],
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 10),
              Text(
                status,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              )
            ],
          ),
          SizedBox(height: 15),
          Text(
            "Requested: $dateRequested",
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}