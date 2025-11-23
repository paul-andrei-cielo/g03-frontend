import 'package:flutter/material.dart';
import 'registrar_dashboard.dart';
import 'staff_all_requests_screen.dart';
import 'registrar_profile_screen.dart';

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

  Map<String, dynamic>? requestData;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(rfidFocus);
    });
  }

  @override
  void dispose() {
    rfidController.dispose();
    rfidFocus.dispose();
    super.dispose();
  }

  // Simulated Scan
  void handleScan(String code) {
    setState(() {
      requestData = {
        "reference": "#68ebba15",
        "student": "Jereeza Mae Lapara",
        "document": "Honorable Dismissal",
        "status": "FOR PICKUP",
        "dateRequested": "11/05/2025 • 10:45 AM",
        "pickupNote": "Please bring your student ID for RFID authentication.",
      };
    });

    rfidController.clear();
    FocusScope.of(context).requestFocus(rfidFocus);
  }

  Color getStatusColor(String status) {
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

                // LOGO
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

                // NAV ITEMS
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
                        _navItem(Icons.rss_feed, "RFID Claim",
                            isActive: true),
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
                                isCollapsed
                                    ? Icons.menu_open
                                    : Icons.menu,
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

                    SizedBox(height: 30),

                    // RFID SCAN BOX
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
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

                    SizedBox(height: 30),

                    if (requestData != null)
                      _buildClaimCard(requestData!),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------
  // NAV ITEM
  // ------------------------------------
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

  // ------------------------------------
  // CLAIM CARD
  // ------------------------------------
  Widget _buildClaimCard(Map<String, dynamic> data) {
    final color = getStatusColor(data["status"]);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              blurRadius: 6, offset: Offset(0, 2), color: Colors.black12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data["reference"],
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "${data["student"]} • ${data["document"]}",
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 15),

          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 10),
              Text(
                data["status"],
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
            "Requested: ${data["dateRequested"]}",
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 20),
          Text(
            data["pickupNote"],
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
            ),
          ),

          SizedBox(height: 25),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                padding:
                    EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Confirm Claim",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
