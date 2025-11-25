import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'registrar_dashboard.dart';
import 'staff_all_requests_screen.dart';
import 'registrar_profile_screen.dart';
import 'rfid_claim_screen.dart';

const String baseUrl = 'https://g03-backend.onrender.com';

class StaffViewRequestScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final String token;

  const StaffViewRequestScreen({
    super.key,
    required this.request,
    required this.token,
  });

  @override
  State<StaffViewRequestScreen> createState() => _StaffViewRequestScreenState();
}

class _StaffViewRequestScreenState extends State<StaffViewRequestScreen> {
  bool isCollapsed = false;
  late String selectedStatus;
  late String initialRemarks;
  late TextEditingController remarksController;

  // FIX: avoid LateInitializationError
  bool isEditable = false;

  // NEW: Add loading state to prevent multiple updates
  bool isUpdating = false;

  final List<String> statusOptions = [
    'FOR CLEARANCE',
    'FOR PAYMENT',
    'PROCESSING',
    'FOR PICKUP',
    'REJECTED',
  ];

  @override
  void initState() {
    super.initState();

    selectedStatus = widget.request['status']?.toString() ?? 'FOR CLEARANCE';
    initialRemarks = widget.request['remarks']?.toString() ?? '';
    remarksController = TextEditingController(text: initialRemarks);

    isEditable = statusOptions.contains(selectedStatus);
  }

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }
  
  Future<void> _updateRequest({String? newStatus, String? newRemarks}) async {
    if (!isEditable) return;

    // NEW: Set loading state at the start
    setState(() => isUpdating = true);

    try {
      final Map<String, dynamic> updateBody = {
        "status": newStatus,
        "remarks": newRemarks,
      };

      final response = await http.put(
        Uri.parse(
          '$baseUrl/requests/updaterequest/${widget.request['_id'] ?? widget.request['id']}',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        setState(() {
          selectedStatus = newStatus!;
          initialRemarks = newRemarks!;
          remarksController.text = newRemarks!;
          widget.request.addAll(responseData['request'] ?? {});
          // NEW: Reset loading state on success
          isUpdating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pop();
      } else {
        // NEW: Reset loading state on failure
        setState(() => isUpdating = false);
        throw Exception('Failed to update request: ${response.body}');
      }
    } catch (e) {
      // NEW: Reset loading state on error
      setState(() => isUpdating = false);
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Update'),
          content: const Text('Are you sure you want to update the request?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(); // close dialog

                _updateRequest(
                  newStatus: selectedStatus,
                  newRemarks: remarksController.text.trim(),
                );
              },
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
    final documentNames =
        documents.map((doc) => doc['name']?.toString() ?? 'Unnamed').toList();

    final referenceId = widget.request['reference_id']?.toString() ?? 'N/A';
    final studentNumber = student['student_number']?.toString() ?? 'N/A';
    final firstName = student['first_name']?.toString() ?? '';
    final lastName = student['last_name']?.toString() ?? '';
    final program = student['program']?.toString() ?? 'N/A';

    final requestDate = widget.request['request_date'] != null
        ? DateTime.tryParse(widget.request['request_date'].toString())
                ?.toLocal()
                .toString()
                .split(' ')[0] ??
            'N/A'
        : 'N/A';

    // UPDATED: Payment verified by details - Use first_name and last_name from staff schema, with type checking
    final paymentVerifiedBy = widget.request['payment_verified_by'];
    final verifierName = paymentVerifiedBy != null && paymentVerifiedBy is Map<String, dynamic>
        ? '${paymentVerifiedBy['first_name']?.toString() ?? ''} ${paymentVerifiedBy['last_name']?.toString() ?? ''}'.trim().isNotEmpty
            ? '${paymentVerifiedBy['first_name']?.toString() ?? ''} ${paymentVerifiedBy['last_name']?.toString() ?? ''}'.trim()
            : 'Unknown Staff'
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          _buildSidebar(),

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
                                setState(() => isCollapsed = !isCollapsed);
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

                    // DETAILS CARD
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
                                _buildDetailRow(
                                    Icons.tag, 'Reference Number', referenceId),
                                const SizedBox(height: 15),

                                _buildDetailRow(
                                  Icons.description,
                                  'Documents Requested',
                                  documentNames.isNotEmpty
                                      ? documentNames.join(', ')
                                      : 'None',
                                ),
                                const SizedBox(height: 15),

                                _buildDetailRow(Icons.school, 'Student Number',
                                    studentNumber),
                                const SizedBox(height: 15),

                                _buildDetailRow(Icons.person, 'Student Name',
                                    '$firstName $lastName'),
                                const SizedBox(height: 15),

                                _buildDetailRow(Icons.book, 'Program', program),
                                const SizedBox(height: 15),

                                _buildDetailRow(
                                    Icons.calendar_today,
                                    'Date Requested',
                                    requestDate),
                                const SizedBox(height: 15),

                                // Display Payment Verified By if available
                                if (verifierName != null)
                                  _buildDetailRow(Icons.verified_user,
                                      'Payment Verified By', verifierName),
                                if (verifierName != null) const SizedBox(height: 15),

                                isEditable
                                    ? _buildStatusDropdown()
                                    : _buildStatusReadOnly(),
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

  // -------------------------------------------------------
  // SIDEBAR (RFID style, no active highlight)
  // -------------------------------------------------------
  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 80 : 250,
      color: Colors.red[900],
      child: Column(
        children: [
          const SizedBox(height: 30),

          // Logo Section
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
                    child: Image.asset('assets/images/Req-ITLogo.png',
                        fit: BoxFit.cover),
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

          // Navigation
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
                  _navItem(Icons.rss_feed, "RFID Claim", onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RfidClaimScreen(token: widget.token),
                      ),
                    );
                  }),
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
    );
  }

  Widget _navItem(IconData icon, String label, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.8), size: 26),
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
              ]
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // UI Helpers
  // -------------------------------------------------------

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
            style: const TextStyle(fontSize: 16, color: Colors.black54),
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
              items: statusOptions
                  .map((String status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() => selectedStatus = newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusReadOnly() {
    return _buildDetailRow(Icons.info, 'Status', selectedStatus);
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        TextField(
          controller: remarksController,
          maxLines: 3,
          enabled: isEditable,
          decoration: InputDecoration(
            hintText: isEditable
                ? 'Add remarks (e.g., rejection reason)'
                : 'Remarks are read-only',
            filled: true,
            fillColor: isEditable ? Colors.grey[100] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            ElevatedButton(
              // UPDATED: Disable button if updating or not editable
              onPressed: (isEditable && !isUpdating) ? _showUpdateConfirmationDialog : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isUpdating ? Colors.grey : Colors.red[900],  // NEW: Visual feedback
                foregroundColor: Colors.white,
              ),
              child: isUpdating
                  ? const SizedBox(  // NEW: Show loading indicator
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Update'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }
}