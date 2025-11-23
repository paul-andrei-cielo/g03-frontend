import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:registrar_app/screens/rfid_claim_screen.dart';
import 'requests_by_status.dart';
import 'staff_all_requests_screen.dart';

const String baseUrl = 'https://g03-backend.onrender.com';

class RegistrarDashboard extends StatefulWidget {
  const RegistrarDashboard({super.key, required this.token});

  final String token;

  @override
  State<RegistrarDashboard> createState() => _RegistrarDashboardState();
}

class _RegistrarDashboardState extends State<RegistrarDashboard> {
  bool isCollapsed = false;

  // Status display order
  final List<String> statusOrder = [
    "FOR CLEARANCE",
    "FOR PAYMENT",
    "PROCESSING",
    "FOR PICKUP",
    "CLAIMED",
    "CANCELLED",
    "REJECTED",
  ];

  // Live counts (initially zero)
  Map<String, int> statusCounts = {
    "FOR CLEARANCE": 0,
    "FOR PAYMENT": 0,
    "PROCESSING": 0,
    "FOR PICKUP": 0,
    "CLAIMED": 0,
    "CANCELLED": 0,
    "REJECTED": 0,
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequestCounts();
  }

  /// -------------------------
  /// FETCH DATA FROM BACKEND
  /// -------------------------
  Future<void> fetchRequestCounts() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/requests/requestcounts"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['counts'] != null && data['counts'] is Map) {
          final Map<String, int> newCounts = {};
          for (String key in statusOrder) {
            if (data['counts'][key] != null) {
              final val = data['counts'][key];
              newCounts[key] = (val is int) ? val : int.tryParse(val.toString()) ?? 0;
            } else {
              newCounts[key] = 0;
            }
          }

          setState(() {
            statusCounts = newCounts;
            isLoading = false;
          });
        } else {
          print("API returned invalid counts: ${data['counts']}");
          setState(() => isLoading = false);
        }
      } else {
        print("Failed to fetch request counts: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching request counts: $e");
      setState(() => isLoading = false);
    }
  }

  /// -------------------------
  /// REFRESH COUNTS AFTER UPDATE
  /// -------------------------
  Future<void> refreshCountsAfterUpdate() async {
    await fetchRequestCounts();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final boxPadding = screenHeight * 0.015;
    final countFontSize = screenHeight * 0.03;
    final titleFontSize = screenHeight * 0.018;

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
                // Sidebar items
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildNavItem(Icons.home, "Dashboard", onTap: () {}),
                        _buildNavItem(Icons.description, "Requests", onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllRequestsScreen(token: widget.token),
                            ),
                          );
                        }),
                        _buildNavItem(Icons.rss_feed, "RFID Claim", onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RfidClaimScreen(token: widget.token),
                            ),
                          );
                        }),
                        _buildNavItem(Icons.person, "Profile"),
                      ],
                    ),
                  ),
                ),
                _buildNavItem(Icons.logout, "Logout", onTap: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
                            const Text(
                              "Registrar Dashboard",
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
                    ),
                    const SizedBox(height: 20),
                    // Summary section
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                Expanded(child: _buildSummaryRow(0, 1, boxPadding, countFontSize, titleFontSize)),
                                const SizedBox(height: 10),
                                Expanded(child: _buildSummaryRow(2, 3, boxPadding, countFontSize, titleFontSize)),
                                const SizedBox(height: 10),
                                Expanded(child: _buildSummaryRow(4, 5, boxPadding, countFontSize, titleFontSize)),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(child: _box(6, boxPadding, countFontSize, titleFontSize)),
                                      const SizedBox(width: 10),
                                      const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                ),
                              ],
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

  Widget _buildSummaryRow(int i1, int i2, double pad, double countSize, double titleSize) {
    return Row(
      children: [
        Expanded(child: _box(i1, pad, countSize, titleSize)),
        const SizedBox(width: 10),
        Expanded(child: _box(i2, pad, countSize, titleSize)),
      ],
    );
  }

  Widget _box(int index, double padding, double countSize, double titleSize) {
    String status = statusOrder[index];
    String count = (statusCounts[status] ?? 0).toString();
    return _buildSummaryBox(
      status,
      count,
      padding: padding,
      countSize: countSize,
      titleSize: titleSize,
      onTap: () => _navigateToStatus(status),
    );
  }

  void _navigateToStatus(String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestsByStatusScreen(
          status: status,
          token: widget.token,
          refreshDashboard: refreshCountsAfterUpdate,
        ),
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

  Widget _buildSummaryBox(
    String title,
    String count, {
    required double padding,
    required double countSize,
    required double titleSize,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padding),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: titleSize,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: countSize,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
