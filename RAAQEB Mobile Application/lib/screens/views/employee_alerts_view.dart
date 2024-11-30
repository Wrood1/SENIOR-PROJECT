import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/employee_alerts_model.dart';
import '../controllers/employee_alerts_controller.dart';
import '../../utils/colors.dart';

class SafetyPersonComplaintsPage extends StatefulWidget {
  final String safetyPersonId;

  const SafetyPersonComplaintsPage({
    super.key,
    required this.safetyPersonId,
  });

  @override
  _SafetyPersonComplaintsPageState createState() => _SafetyPersonComplaintsPageState();
}

class _SafetyPersonComplaintsPageState extends State<SafetyPersonComplaintsPage> {
  late ComplaintsController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = ComplaintsController(safetyPersonId: widget.safetyPersonId);
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _controller.fetchUserData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors().backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors().primaryColor),
          ),
        ),
      );
    }

    if (_controller.factoryManagerId == null) {
      return Scaffold(
        backgroundColor: AppColors().backgroundColor,
        body: Center(
          child: Text(
            'Error: Unable to load user data',
            style: TextStyle(color: AppColors().primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors().backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Pending Complaints',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors().primaryColor,
        elevation: 0,
      ),
      body: _buildComplaintsList(),
    );
  }

  Widget _buildComplaintsList() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _controller.getComplaintsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: AppColors().primaryColor),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors().primaryColor),
            ),
          );
        }

        final complaints = snapshot.data ?? [];

        if (complaints.isEmpty) {
          return Center(
            child: Text(
              'No pending complaints',
              style: TextStyle(
                fontSize: 16,
                color: AppColors().primaryColor,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaintData = complaints[index].data() as Map<String, dynamic>;
            final complaint = Complaint.fromFirestore(complaintData);
            return _buildComplaintCard(complaint, complaints[index].id);
          },
        );
      },
    );
  }

  Widget _buildComplaintCard(Complaint complaint, String complaintId) {
    final dateStr = DateFormat('MMM dd, yyyy - HH:mm').format(complaint.timestamp.toDate());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: AppColors().primaryColor),
                const SizedBox(width: 8),
                FutureBuilder<String?>(
                  future: _controller.getEmployeeName(complaint.employeeId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors().primaryColor,
                        ),
                      );
                    }
                    return const Text('Loading...');
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              complaint.complaint,
              style: TextStyle(
                fontSize: 16,
                color: AppColors().primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 12,
                color: AppColors().primaryColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showResponseDialog(complaintId),
              icon: const Icon(Icons.reply),
              label: const Text('Respond'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors().primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResponseDialog(String complaintId) {
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Respond to Complaint',
          style: TextStyle(color: AppColors().primaryColor),
        ),
        content: TextField(
          controller: responseController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter your response',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors().primaryColor.withOpacity(0.8)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (responseController.text.isNotEmpty) {
                try {
                  await _controller.submitResponse(
                    complaintId,
                    responseController.text,
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Response submitted successfully')),
                  );
                  
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to submit response. Please try again.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors().primaryColor,
            ),
            child: const Text('Submit'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.grey.shade100,
      ),
    );
  }
}