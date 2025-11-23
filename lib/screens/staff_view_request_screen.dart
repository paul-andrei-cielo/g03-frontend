import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'registrar_dashboard.dart'; // Dashboard import
import 'staff_all_requests_screen.dart'; // All requests screen

const String baseUrl = 'https://g03-backend.onrender.com';

class StaffViewRequestScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final String token;

  const StaffViewRequestScreen({super.key, required this.request, required this.token});

  @override
  State<StaffViewRequestScreen> createState() => _StaffViewRequestScreenState();
}

class _StaffViewRequestScreenState extends State<StaffViewRequestScreen> {
  bool isCollapsed = false;
  late String selectedStatus;
  late String initialRemarks;
  late TextEditingController remarksController;

  final List<String> statusOptions = [
    'FOR CLEARANCE',
    'FOR PAYMENT',
    'PROCESSING',
    'FOR PICKUP',
    'CLAIMED',
    'CANCELLED',
    'REJECTED'
  ];

  @override
  void initState() {
    super.initState();

    // Safely initialize status and remarks
    selectedStatus = widget.request['status']?.toString() ?? 'FOR CLEARANCE';
    initialRemarks = widget.request['remarks']?.toString() ?? '';
    remarksController = TextEditingController(text: initialRemarks);
  }

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }

  Future<void> _updateRequest({String? newStatus, String? newRemarks}) async {
    try {
      final Map<String, dynamic> updateBody = {};
      if (newStatus != null && newStatus != widget.request['status']) updateBody['status'] = newStatus;
      if (newRemarks != null && newRemarks != initialRemarks) updateBody['remarks'] = newRemarks;

      if (updateBody.isEmpty) return;

      final response = await http.put(
        Uri.parse('${baseUrl}/requests/updaterequest/${widget.request['_id'] ?? widget.request['id']}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateBody),
      );

      if (response.statusCode == 200) {
        setState(() {
          if (newStatus != null) {
            selectedStatus = newStatus;
            widget.request['status'] = newStatus;
          }
          if (newRemarks != null) {
            initialRemarks = newRemarks;
            remarksController.text = newRemarks;
            widget.request['remarks'] = newRemarks;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Failed to update request: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating request: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showUpdateConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Update'),
          content: const Text('Are you sure you want to update the request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateRequest(
                  newStatus: selectedStatus,
                  newRemarks: remarksController.text.trim(),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.request['student_id'] ?? {};
    final documents = widget.request['documents'] as List<dynamic>? ?? [];
    final documentNames = documents.map((doc) => doc['name']?.toString() ?? 'Unnamed').toList();

    // Safely handle all potentially null fields
    final referenceId = widget.request['reference_id']?.toString() ?? 'N/A';
    final studentNumber = student['student_number']?.toString() ?? 'N/A';
    final firstName = student['first_name']?.toString() ?? 'Unknown';
    final lastName = student['last_name']?.toString() ?? '';
    final program = student['program']?.toString() ?? 'N/A';
    final requestDate = widget.request['request_date'] != null
        ? DateTime.tryParse(widget.request['request_date'].toString())?.toLocal().toString().split(' ')[0] ?? 'N/A'
        : 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCollapsed ? 80 : 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[900]!, Colors.red[700]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                if (!isCollapsed)
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/Req-ITLogo.png',
                          fit: BoxFit.cover,
                        ),
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
                              'Request Details',
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
                    Expanded(
                      child: SingleChildScrollView(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(Icons.tag, 'Reference Number', referenceId),
                                const SizedBox(height: 15),
                                _buildDetailRow(Icons.description, 'Documents Requested',
                                    documentNames.isNotEmpty ? documentNames.join(', ') : 'None'),
                                const SizedBox(height: 15),
                                _buildDetailRow(Icons.school, 'Student Number', studentNumber),
                                const SizedBox(height: 15),
                                _buildDetailRow(Icons.person, 'Student Name', '$firstName $lastName'),
                                const SizedBox(height: 15),
                                _buildDetailRow(Icons.book, 'Program', program),
                                const SizedBox(height: 15),
                                _buildDetailRow(Icons.calendar_today, 'Date Requested', requestDate),
                                const SizedBox(height: 20),
                                _buildStatusDropdown(),
                                const SizedBox(height: 20),
                                _buildRemarksField(),
                              ],
                            ),
                          ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.red[900], size: 24),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Row(
      children: [
        Icon(Icons.info, color: Colors.red[900], size: 24),
        const SizedBox(width: 10),
        const Text(
          'Status: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              underline: const SizedBox(),
              items: statusOptions.map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedStatus = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemarksField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.comment, color: Colors.red[900], size: 24),
            const SizedBox(width: 10),
            const Text(
              'Remarks: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: remarksController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add remarks (e.g., rejection reason)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _showUpdateConfirmationDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[900],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Update'),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label clicked'),
              behavior: SnackBarBehavior.floating,
            ),
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