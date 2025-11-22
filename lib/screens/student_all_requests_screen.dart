import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'student_request_form.dart';
import 'edit_request_screen.dart';
import 'student_dashboard.dart';

const String baseUrl = 'https://g03-backend.onrender.com';

class StudentAllRequestsScreen extends StatefulWidget {
  final String token;
  const StudentAllRequestsScreen({super.key, required this.token});

  @override
  State<StudentAllRequestsScreen> createState() => _StudentAllRequestsScreenState();
}

class _StudentAllRequestsScreenState extends State<StudentAllRequestsScreen> {
  bool isCollapsed = false;
  String studentName = "Loading...";
  String studentNumber = "Loading...";
  List<dynamic> requests = [];
  bool isLoading = true;
  String errorMessage = '';
  String userId = '';

  @override
  void initState() {
    super.initState();
    fetchUserData().then((_) => fetchRequests());
  }

  Future<void> fetchUserData() async {
    try {
      final payload = json.decode(utf8.decode(base64.decode(widget.token.split('.')[1])));
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
        if (data['success'] == true && data['user'] != null) {
          final user = data['user'];
          setState(() {
            studentName = '${user['first_name'] ?? 'Unknown'} ${user['last_name'] ?? ''}'.trim();
            studentNumber = user['student_number'] ?? 'Unknown';
          });
        }
      }
    } catch (e) {
      setError('Error fetching user data: $e');
    }
  }

  Future<void> fetchRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/requests/$userId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['requests'] is List) {
          setState(() {
            requests = List<dynamic>.from(data['requests']).where((r) => r['status'] != 'CLAIMED').toList(); // Assuming active means not CLAIMED
            isLoading = false;
          });
        } else {
          setError('Failed to load requests: ${data['message'] ?? 'Invalid data'}');
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          setError('Failed to load requests: ${errorData['message'] ?? 'Status ${response.statusCode}'}');
        } catch (e) {
          setError('Failed to load requests: Status ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
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

  Future<void> deleteRequest(String requestId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/requests/deleterequest/$requestId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          requests.removeWhere((r) => r['_id'] == requestId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request deleted successfully')),
        );
      } else {
        setError('Failed to delete request');
      }
    } catch (e) {
      setError('Error deleting request: $e');
    }
  }

  Future<void> uploadProofOfPayment(String requestId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      // Assuming multipart upload to /requests/upload-proof/{requestId}
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/requests/upload-proof/$requestId'));
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.files.add(await http.MultipartFile.fromPath('proof', imageFile.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof uploaded successfully')),
        );
        fetchRequests(); // Refresh to update status if needed
      } else {
        setError('Failed to upload proof');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // SIDEBAR (same as other screens)
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
                            Text(
                              "Hello, ${studentName.split(' ').first}!",
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
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "All Active Requests",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // REQUESTS LIST
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : requests.isEmpty
                                ? const Center(child: Text("No active requests."))
                                : ListView.builder(
                                    itemCount: requests.where((r) => (r['status'] ?? '') != 'CLAIMED').length,
                                    itemBuilder: (context, index) {
                                      final activeRequests = requests.where((r) => (r['status'] ?? '') != 'CLAIMED').toList();
                                      final req = activeRequests[index];
                                      final docNames = (req['documents'] as List?)?.map((d) => d['name'] as String? ?? 'Unknown').join(", ") ?? "No documents";
                                      final status = req['status'] ?? 'Unknown';
                                      final requestId = req['_id'] ?? '';
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 15),
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // =============================
                                            // ROW 1 — TABLE HEADERS
                                            // =============================
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              child: Row(
                                                children: const [
                                                  Expanded(flex: 2,
                                                      child: Text("Reference ID", style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2,
                                                      child: Text("Document Type", style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2,
                                                      child: Text("Date Requested", style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2,
                                                      child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2,
                                                      child: Text("Details", style: TextStyle(fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2,
                                                      child: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                                                ],
                                              ),
                                            ),

                                            const Divider(),

                                            // =============================
                                            // ROW 2 — ROW DATA
                                            // =============================
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Reference ID
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    requestId,
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),

                                                // Document Type
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    docNames,
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),

                                                // Date Requested
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    req['createdAt'] ?? "Unknown",
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),

                                                // Status
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: status == "PENDING (Payment)" ? Colors.orange : Colors.black,
                                                    ),
                                                  ),
                                                ),

                                                // Status Details
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    req['status_details'] ?? "—",
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),

                                                // ACTION BUTTONS
                                                Expanded(
                                                  flex: 2,
                                                  child: Row(
                                                    children: [
                                                      // EDIT
                                                      if (status == 'PENDING (Clearance)' || status == 'PENDING (Payment)')
                                                        SizedBox(
                                                          height: 32,
                                                          child: ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) =>
                                                                      EditRequestScreen(token: widget.token, request: req),
                                                                ),
                                                              ).then((_) => fetchRequests());
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.blue,
                                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                                            ),
                                                            child: const Text("Edit", style: TextStyle(fontSize: 12)),
                                                          ),
                                                        ),

                                                      const SizedBox(width: 6),

                                                      // DELETE
                                                      SizedBox(
                                                        height: 32,
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (_) => AlertDialog(
                                                                title: const Text("Delete Request"),
                                                                content: const Text("Are you sure you want to delete this request?"),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () => Navigator.pop(context),
                                                                    child: const Text("Cancel"),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.pop(context);
                                                                      deleteRequest(requestId);
                                                                    },
                                                                    child: const Text("Delete"),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.red,
                                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                                          ),
                                                          child: const Text("Delete", style: TextStyle(fontSize: 12)),
                                                        ),
                                                      ),

                                                      if (status == 'PENDING (Payment)') ...[
                                                        const SizedBox(width: 6),
                                                        SizedBox(
                                                          height: 32,
                                                          child: ElevatedButton(
                                                            onPressed: () => uploadProofOfPayment(requestId),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.green,
                                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                                            ),
                                                            child: const Text("Upload", style: TextStyle(fontSize: 12)),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentDashboard(token: widget.token),
              ),
            );
          } else if (label == "History") {
            fetchRequests();
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