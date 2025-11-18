import 'package:flutter/material.dart';
import 'request_summary_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StudentRequestForm extends StatefulWidget {
  final String token; // JWT token from login
  const StudentRequestForm({super.key, required this.token});

  @override
  State<StudentRequestForm> createState() => _StudentRequestFormState();
}

class _StudentRequestFormState extends State<StudentRequestForm> {
  bool isCollapsed = false;
  int _currentStep = 1;

  final TextEditingController _lastSemController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _dateGraduatedController = TextEditingController();
  final TextEditingController _contactNoController = TextEditingController();

  final List<Map<String, dynamic>> _documents = [
    {"name": "Transcript of Records", "price": 500, "selected": false, "remarks": "", "copies": 1},
    {"name": "Certificate of Grades", "price": 100, "selected": false, "remarks": "", "copies": 1},
    {"name": "Certificate of Graduation", "price": 100, "selected": false, "copies": 1},
    {"name": "Certificate of Enrollment", "price": 100, "selected": false, "remarks": "", "copies": 1},
    {"name": "Honorable Dismissal", "price": 850, "selected": false, "copies": 1},
    {"name": "Certificate of Good Moral Character", "price": 100, "selected": false, "copies": 1},
    {"name": "Course Description", "price": 100, "selected": false, "copies": 1},
    {"name": "CAV (CHED)", "price": 500, "selected": false, "copies": 1},
    {"name": "CV (TESDA)", "price": 600, "selected": false, "copies": 1},
    {"name": "RLE Summary (Nursing)", "price": 300, "selected": false, "copies": 1},
    {"name": "Certified True Copy", "price": 100, "selected": false, "copies": 1},
  ];

  double get _totalPrice => _documents
      .where((doc) => doc["selected"])
      .fold(0.0, (sum, doc) => sum + (doc["price"] * doc["copies"]));

  String getSelectedDocumentNames() {
    List<String> selected = _documents
        .where((doc) => doc["selected"])
        .map((doc) => "${doc['name']} (${doc['copies']}x)")
        .toList();

    return selected.join(", ");
  }

  // -------------------------
  // FETCH STUDENT REQUESTS
  // -------------------------
  Future<List<dynamic>> fetchMyRequests() async {
    // Use the correct host for your environment:
    // - Flutter web (dev server): http://localhost:3000
    // - Android emulator: http://10.0.2.2:3000
    // - Physical device / different PC: http://<your-machine-ip>:3000  (enable CORS on backend)
    final url = Uri.parse('http://localhost:3000/requests/mine');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['requests'] as List<dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Unknown server message');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  // -------------------------
  // UI and Form Code
  // -------------------------
  @override
  Widget build(BuildContext context) {
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
                      const SizedBox(height: 10),
                      const Text(
                        "Jereeza Mae Mayuga",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Text(
                        "202300000",
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
                // Navigation items
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
                              "Hello, Jereeza Mae!",
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
                    const Text(
                      "+ Request New Document",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Step content
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _currentStep == 1 ? _buildStep1Form() : _buildStep2Form(),
                      ),
                    ),

                    // Step buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_currentStep == 2)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _currentStep = 1;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[500],
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text("Return"),
                          ),
                        const SizedBox(width: 10),
                        if (_currentStep == 2)
                          ElevatedButton(
                            onPressed: _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[900],
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text("Submit Request"),
                          ),
                        if (_currentStep == 1)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _currentStep = 2;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[900],
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text("Next"),
                          ),
                      ],
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

  // -------------------------
  // SUBMIT REQUEST FUNCTION
  // -------------------------
  void _submitRequest() async {
    try {
      final selectedDocuments = _documents
          .where((doc) => doc["selected"])
          .map((doc) => {
                "name": doc["name"],
                "copies": doc["copies"],
                "remarks": doc["remarks"] ?? "",
                "price": doc["price"]
              })
          .toList();

      final body = {
        "student_id": "202300000",
        "documents": selectedDocuments,
        "contact_no": _contactNoController.text,
        "last_sem_attended": _lastSemController.text,
        "semester": _semesterController.text,
        "date_graduated": _dateGraduatedController.text,
        "total_amount": _totalPrice,
      };

      // Choose correct host for your running environment:
      // - Flutter Web: use 'http://localhost:3000'
      // - Android emulator: use 'http://10.0.2.2:3000'
      // - Physical device: use 'http://<your-machine-ip>:3000' and enable CORS.
      final url = Uri.parse("http://localhost:3000/requests/createrequest");

      print("POST $url");
      print("Request body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(body),
      );

      print("Response code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Server returned status ${response.statusCode}");
      }

      final data = jsonDecode(response.body);

      String? requestId;

      if (data is Map && data["isAdded"] != null && data["isAdded"]["request"] != null) {
        requestId = data["isAdded"]["request"]["_id"]?.toString();
      }

      if (requestId == null && data is Map && data["request"] != null) {
        requestId = data["request"]["_id"]?.toString();
      }

      if (requestId == null && data is Map && data["data"] != null) {
        requestId = data["data"]["id"]?.toString() ?? data["data"]["_id"]?.toString();
      }

      if (requestId == null) {
        throw Exception("Invalid response from server: ${response.body}");
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RequestSummaryScreen(
            requestId: requestId!,
            documentType: getSelectedDocumentNames(),
            copies: 1,
            totalAmount: _totalPrice,
          ),
        ),
      );
    } catch (e) {
      print("ERROR: $e");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Request Failed"),
          content: SingleChildScrollView(child: Text("Something went wrong:\n$e")),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  // Sidebar nav item builder (fixed implementation)
  Widget _buildNavItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          if (label == "Logout") {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          } else if (label == "Dashboard") {
            Navigator.pushReplacementNamed(context, '/student_dashboard', arguments: {'token': widget.token});
          } else if (label == "History") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentRequestsHistoryScreen(token: widget.token),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label clicked')));
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

  // Step 1 & 2 UI code (kept faithful to your original)
  Widget _buildStep1Form() {
    return Container(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Step 1: Personal Information",
              style: TextStyle(
                color: Colors.red[900],
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Last Sem Attended *",
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "School Year",
                    "e.g. 2024–2025",
                    _lastSemController,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    "Semester",
                    "1st / 2nd / Summer",
                    _semesterController,
                  ),
                ),
              ],
            ),
            _buildTextField("Date Graduated", "Optional", _dateGraduatedController),
            _buildTextField("Contact No. *", "", _contactNoController),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Form() {
    return Container(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document List
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Step 2: Credentials Applied",
                  style: TextStyle(
                    color: Colors.red[900],
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: _documents.map((doc) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            activeColor: Colors.red[900],
                            value: doc["selected"],
                            onChanged: (val) {
                              setState(() => doc["selected"] = val!);
                            },
                            title: Text(
                              doc["name"],
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            secondary: Text(
                              "₱${doc["price"]}",
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Copies
                          if (doc["selected"])
                            Padding(
                              padding: const EdgeInsets.only(left: 40, right: 20, bottom: 10),
                              child: Row(
                                children: [
                                  const Text(
                                    "Copies:",
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 70,
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          doc["copies"] = int.tryParse(value) ?? 1;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Remarks (if applicable)
                          if (doc.containsKey("remarks") && doc["selected"])
                            Padding(
                              padding: const EdgeInsets.only(left: 40, right: 20, bottom: 10),
                              child: TextField(
                                onChanged: (value) => doc["remarks"] = value,
                                decoration: InputDecoration(
                                  hintText: "Remarks (optional)",
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Total Price
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Text(
                  "Total",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Container(height: 2, color: Colors.black),
                const SizedBox(height: 10),
                Text(
                  "₱ ${_totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}

// -------------------------
// STUDENT REQUEST HISTORY SCREEN
// -------------------------
class StudentRequestsHistoryScreen extends StatelessWidget {
  final String token;
  const StudentRequestsHistoryScreen({super.key, required this.token});

  Future<List<dynamic>> fetchMyRequests() async {
    final url = Uri.parse('http://localhost:3000/requests/mine');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) return data['requests'];
      throw Exception(data['message']);
    } else {
      throw Exception('Server error ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Requests")),
      body: FutureBuilder<List<dynamic>>(
        future: fetchMyRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final requests = snapshot.data!;
          if (requests.isEmpty) return const Center(child: Text("No requests yet."));
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final docNames = (req['doc_type_id'] as List).map((d) => d['doc_name']).join(", ");
              return ListTile(
                title: Text(docNames),
                subtitle: Text("Status: ${req['status']}"),
              );
            },
          );
        },
      ),
    );
  }
}