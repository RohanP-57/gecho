import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/registration_service.dart';

class ApprovalRequestsScreen extends StatefulWidget {
  const ApprovalRequestsScreen({super.key});

  @override
  State<ApprovalRequestsScreen> createState() => _ApprovalRequestsScreenState();
}

class _ApprovalRequestsScreenState extends State<ApprovalRequestsScreen> {
  final RegistrationService _registrationService = RegistrationService();

  @override
  void initState() {
    super.initState();
    // Clean up expired requests when screen loads
    _registrationService.cleanupExpiredRequests();
  }

  Future<void> _approveRequest(String email, Map<String, dynamic> data) async {
    try {
      await _registrationService.approveRegistrationRequest(email, 'admin@gla.ac.in');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Approved ${data['name']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String email, Map<String, dynamic> data) async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject ${data['name']}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject this request?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Please provide a reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _registrationService.rejectRegistrationRequest(email, 'admin@gla.ac.in', result);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Rejected ${data['name']}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showRequestDetails(String email, Map<String, dynamic> data) {
    final submittedAt = (data['submittedAt'] as Timestamp).toDate();
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    final timeLeft = expiresAt.difference(DateTime.now());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: data['userType'] == 'student' 
                  ? Colors.green.shade100 
                  : Colors.blue.shade100,
              child: Icon(
                data['userType'] == 'student' ? Icons.school : Icons.group,
                color: data['userType'] == 'student' 
                    ? Colors.green.shade600 
                    : Colors.blue.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? 'Unknown'),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Account Type', data['userType']?.toString().toUpperCase() ?? 'N/A'),
              
              if (data['userType'] == 'student') ...[
                _buildDetailRow('Student ID', data['studentId'] ?? 'N/A'),
                _buildDetailRow('Department', data['department'] ?? 'N/A'),
              ] else ...[
                _buildDetailRow('Club Name', data['clubName'] ?? 'N/A'),
                _buildDetailRow('Club Type', data['clubType'] ?? 'N/A'),
              ],
              
              _buildDetailRow('Reason', data['reason'] ?? 'No reason provided'),
              _buildDetailRow('Submitted', _formatDateTime(submittedAt)),
              _buildDetailRow('Expires', _formatDateTime(expiresAt)),
              _buildDetailRow('Time Left', '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m'),
              
              if (timeLeft.inHours < 24) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Expires soon!',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectRequest(email, data);
            },
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _approveRequest(email, data);
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRequestCard(String email, Map<String, dynamic> data) {
    final submittedAt = (data['submittedAt'] as Timestamp).toDate();
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    final timeLeft = expiresAt.difference(DateTime.now());
    final isExpiringSoon = timeLeft.inHours < 24;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showRequestDetails(email, data),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: data['userType'] == 'student' 
                        ? Colors.green.shade100 
                        : Colors.blue.shade100,
                    child: Icon(
                      data['userType'] == 'student' ? Icons.school : Icons.group,
                      color: data['userType'] == 'student' 
                          ? Colors.green.shade600 
                          : Colors.blue.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isExpiringSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '⚠️ ${timeLeft.inHours}h left',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Quick info
              Row(
                children: [
                  Chip(
                    label: Text(
                      data['userType']?.toString().toUpperCase() ?? 'UNKNOWN',
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: data['userType'] == 'student' 
                        ? Colors.green.shade100 
                        : Colors.blue.shade100,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data['userType'] == 'student' 
                        ? 'ID: ${data['studentId'] ?? 'N/A'}'
                        : data['clubName'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(email, data),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectRequest(email, data),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Requests'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _registrationService.getPendingRegistrationRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final requests = snapshot.data?.docs ?? [];
          
          // Sort requests by submittedAt on client side (newest first)
          requests.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = (aData['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (bData['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime); // Descending order (newest first)
          });
          
          // Limit to 20 requests max
          final limitedRequests = requests.take(20).toList();

          if (limitedRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All registration requests have been processed',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header with count
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    Icon(Icons.pending_actions, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    Text(
                      '${limitedRequests.length} Pending Request${limitedRequests.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    if (requests.length > 20) ...[
                      const Spacer(),
                      Text(
                        'Showing 20 of ${requests.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Requests list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: limitedRequests.length,
                  itemBuilder: (context, index) {
                    final doc = limitedRequests[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final email = doc.id;
                    
                    return _buildRequestCard(email, data);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}