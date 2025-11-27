import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:registrar_app/screens/student_all_requests_screen.dart';
import 'dart:convert';
import 'request_summary_screen.dart';
import 'student_dashboard.dart';
import 'student_request_form.dart';

const String baseUrl = 'https://g03-backend.onrender.com';

class EditRequestScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> request;

  const EditRequestScreen({super.key, required this.token, required this.request});

  @override
  State<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  bool isCollapsed = false;
  int _currentStep = 1;

  final TextEditingController _lastSemController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _dateGraduatedController = TextEditingController();
  final TextEditingController _contactNoController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  String studentName = "Loading...";
  String studentNumber = "Loading...";
  String studentId = "";

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

  int getTotalCopies() {
    return _documents
      .where((doc) => doc["selected"])
      .fold<int>(0, (sum, doc) => sum + (doc["copies"] as int));
  }

  @override
  void initState() {
    super.initState();
    fetchStudentData();
    // Pre-fill with existing request data
    _purposeController.text = widget.request['purpose'] ?? '';
    _contactNoController.text = widget.request['contact_number'] ?? '';
    _lastSemController.text = widget.request['last_sem_attended'] ?? '';
    _semesterController.text = widget.request['semester'] ?? '';
    _dateGraduatedController.text = widget.request['date_graduated'] ?? '';
    // Pre-select documents from the request
    List<dynamic> existingDocs = widget.request['documents'] ?? [];
    for (var doc in _documents) {
      var existing = existingDocs.firstWhere(
        (e) => e['name'] == doc['name'],
        orElse: () => null,
      );
      if (existing != null) {
        doc['selected'] = true;
        doc['copies'] = existing['copies'] ?? 1;
        doc['remarks'] = existing['remarks'] ?? '';
      }
    }
  }

  Future<void> fetchStudentData() async {
    try {
      final payload = json.decode(utf8.decode(base64.decode(widget.token.split('.')[1])));
      final userId = payload['id'];
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final user = data['user'];
          setState(() {
            studentName = '${user['first_name'] ?? 'Unknown'} ${user['last_name'] ?? ''}'.trim();
            studentNumber = user['student_number'] ?? 'Unknown';
            studentId = userId;
          });
        }
      }
    } catch (e) {
      print('Error fetching student data: $e');
    }
  }

  Future<void> updateRequest() async {
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student data not loaded. Try again.')));
      return;
    }
    if (_documents.where((d) => d['selected']).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one document.')));
      return;
    }
    if (_contactNoController.text.isEmpty || _lastSemController.text.isEmpty || _semesterController.text.isEmpty || _purposeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all required fields.')));
      return;
    }

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
        "student_id": studentId,
        "documents": selectedDocuments,
        "purpose": _purposeController.text,
        "contact_number": _contactNoController.text,
        "last_sem_attended": _lastSemController.text,
        "semester": _semesterController.text,
        "date_graduated": _dateGraduatedController.text,
        "total_amount": _totalPrice,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/requests/updatemyrequest/${widget.request['_id']}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request updated successfully')),
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestSummaryScreen(
                requestId: widget.request['_id'],
                token: widget.token,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: ${data['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar (same as StudentRequestForm)
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
                    const SizedBox(height: 25),
                    const Text(
                      "Edit Request",
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
                              foregroundColor: Colors.white,
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
                            onPressed: updateRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[900],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text("Update Request"),
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
                              foregroundColor: Colors.white,
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

  Widget _buildNavItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          if (label == "Logout") {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          } else if (label == "Dashboard") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentDashboard(token: widget.token),
              )
            );
          } else if (label == "Request") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentRequestForm(token: widget.token),
              ),
            );
          } else if (label == "History") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentAllRequestsScreen(token: widget.token),
              )
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
            _buildTextField("Purpose *", "e.g., For employment", _purposeController),
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
                                      controller: TextEditingController(text: doc["copies"].toString()),
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
                                controller: TextEditingController(text: doc["remarks"]),
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