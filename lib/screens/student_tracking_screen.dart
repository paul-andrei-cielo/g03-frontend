import 'package:flutter/material.dart';

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

  // ────────────────────────────────────────────────
  // TEMPORARY MOCK TIMELINE DATA (replace with backend later)
  // ────────────────────────────────────────────────
  List<Map<String, dynamic>> timeline = [
    {
      "status": "For Clearance",
      "details": "Clearance verification is ongoing.",
      "timestamp": "11/05/2025\n10:45:11",
      "color": Color(0xFFF4C542),
    },
    {
      "status": "For Payment",
      "details": "Your clearance has been verified. Please upload your proof of payment.",
      "timestamp": "11/06/2025\n9:40:23",
      "color": Color(0xFFF28C28),
      "upload": true
    },
    {
      "status": "Preparing",
      "details": "Your proof of payment has been verified. Please stand by while your document is being prepared.",
      "timestamp": "11/06/2025\n9:40:23",
      "color": Color(0xFF3A82F7),
    },
    {
      "status": "For Pickup",
      "details": "Your document is ready to be picked up. You may claim it at the registrar’s office.\nImportant: Please bring your student ID for RFID authentication.",
      "timestamp": "11/10/2025\n11:40:14",
      "color": Color(0xFF8A4FFF),
    },
    {
      "status": "Claimed",
      "details": "You have successfully claimed your document. Thank you.",
      "timestamp": "11/11/2025\n12:45:11",
      "color": Color(0xFF4CAF50),
    },
  ];

  // Cancel Request Dialog
  void _cancelRequest() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Request"),
        content: const Text("Are you sure you want to cancel this request?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Request cancelled.")),
              );
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reference = widget.request['reference'] ?? "#68ebba15";
    final document = widget.request['document'] ?? "Honorable Dismissal";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ───────────────────────────────────────────────
          // SIDEBAR — MATCHED FROM DASHBOARD
          // ───────────────────────────────────────────────
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
                          child: Image.asset('assets/images/Req-ITLogo.png'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Student Name",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Text(
                        "202301299",
                        style: TextStyle(
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
                    child: Image.asset('assets/images/Req-ITLogo.png',
                        width: 45, height: 45),
                  ),
                const SizedBox(height: 40),

                // NAV
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: const [
                        _SidebarItem(Icons.home, "Dashboard"),
                        _SidebarItem(Icons.article, "Request"),
                        _SidebarItem(Icons.search, "Tracking"),
                        _SidebarItem(Icons.history, "History"),
                        _SidebarItem(Icons.person, "Profile"),
                        _SidebarItem(Icons.help, "Help"),
                      ],
                    ),
                  ),
                ),
                const _SidebarItem(Icons.logout, "Logout"),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ───────────────────────────────────────────────
          // MAIN CONTENT
          // ───────────────────────────────────────────────
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
                                setState(() => isCollapsed = !isCollapsed);
                              },
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Hello, Jereeza Mae!",
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ],
                        ),
                        Image.asset(
                          'assets/images/Req-ITLongLogo.png',
                          height: 60,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // REFERENCE TITLE + CANCEL BUTTON
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Reference $reference | $document",
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _cancelRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Cancel Request",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
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
                                // DATE/TIME
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    item["timestamp"],
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 20),

                                // TIMELINE DOT + LINE
                                Column(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: item["color"],
                                      ),
                                    ),
                                    if (index != timeline.length - 1)
                                      Container(
                                        width: 2,
                                        height: 60,
                                        color: Colors.grey.shade400,
                                      ),
                                  ],
                                ),

                                const SizedBox(width: 20),

                                // STATUS + DETAILS
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item["status"],
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: item["color"],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item["details"],
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),

                                      // UPLOAD BUTTON
                                      if (hasUpload)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.grey.shade300,
                                              foregroundColor: Colors.black,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 22,
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                              ),
                                            ),
                                            child: const Text(
                                              "Upload",
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SidebarItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
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
        ),
      ),
    );
  }
}
