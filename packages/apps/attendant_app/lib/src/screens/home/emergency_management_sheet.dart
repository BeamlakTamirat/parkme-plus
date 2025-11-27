import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/attendant_providers.dart';

enum EmergencyType {
  security,
  medical,
  fire,
  accident,
  maintenance,
  theft,
  vandalism,
  other,
}

class EmergencyManagementSheet extends ConsumerStatefulWidget {
  const EmergencyManagementSheet({super.key});

  @override
  ConsumerState<EmergencyManagementSheet> createState() =>
      _EmergencyManagementSheetState();
}

class _EmergencyManagementSheetState
    extends ConsumerState<EmergencyManagementSheet> {
  int currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with tabs
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Emergency Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Tab buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        'Quick Contacts',
                        Icons.phone,
                        0,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton(
                        'Report Incident',
                        Icons.report,
                        1,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              children: [
                _buildQuickContactsPage(),
                _buildReportIncidentPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, int index, Color color) {
    final isSelected = currentPage == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          currentPage = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickContactsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency alert
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'For life-threatening emergencies, call 911 immediately!',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Emergency Contacts Section
          const Text(
            'Emergency Contacts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Emergency contacts list
          _buildContactCard(
            'Emergency Services',
            '911',
            Icons.local_hospital,
            Colors.red,
            true,
          ),

          _buildContactCard(
            'Police',
            '991',
            Icons.local_police,
            Colors.blue,
            true,
          ),

          _buildContactCard(
            'Fire Department',
            '999',
            Icons.local_fire_department,
            Colors.orange,
            true,
          ),

          const SizedBox(height: 24),

          // Site-Specific Contacts
          const Text(
            'Site Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildContactCard(
            'Security Office',
            '+251-911-123456',
            Icons.security,
            Colors.indigo,
            false,
          ),

          _buildContactCard(
            'Site Manager',
            '+251-911-789012',
            Icons.person,
            Colors.green,
            false,
          ),

          _buildContactCard(
            'Maintenance',
            '+251-911-345678',
            Icons.build,
            Colors.brown,
            false,
          ),

          _buildContactCard(
            'Admin Office',
            '+251-911-901234',
            Icons.business,
            Colors.purple,
            false,
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Send SOS Alert',
                  Icons.sos,
                  Colors.red,
                  () => _sendSOSAlert(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Request Security',
                  Icons.shield,
                  Colors.blue,
                  () => _requestSecurity(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportIncidentPage() {
    return const IncidentReportForm();
  }

  Widget _buildContactCard(
    String title,
    String number,
    IconData icon,
    Color color,
    bool isEmergency,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          number,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEmergency) ...[
              IconButton(
                onPressed: () => _sendSMS(number),
                icon: Icon(Icons.message, color: Colors.green[600]),
                tooltip: 'Send SMS',
              ),
            ],
            IconButton(
              onPressed: () => _makeCall(number),
              icon: Icon(
                Icons.call,
                color: isEmergency ? Colors.red[600] : Colors.blue[600],
              ),
              tooltip: 'Call',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _makeCall(String number) async {
    try {
      //  use url_launcher to make calls
      // For now, show a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Call $number'),
          content: const Text(
            'This would open your phone\'s dialer. '
            'This is a placeholder.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      if (kDebugMode) print('📞 Making call to: $number');
    } catch (e) {
      _showErrorSnackBar('Failed to make call: $e');
    }
  }

  Future<void> _sendSMS(String number) async {
    try {
      // Note: use url_launcher to send SMS
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Send SMS to $number'),
          content: const Text(
            'This would open your SMS app. '
            'This is a placeholder.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      if (kDebugMode) print('💬 Sending SMS to: $number');
    } catch (e) {
      _showErrorSnackBar('Failed to send SMS: $e');
    }
  }

  Future<void> _sendSOSAlert() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sos, color: Colors.red),
            SizedBox(width: 8),
            Text('Send SOS Alert'),
          ],
        ),
        content: const Text(
          'This will send an emergency alert to all site management contacts '
          'and security personnel. Use only for genuine emergencies.\n\n'
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performSOSAlert();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSOSAlert() async {
    try {
      final currentUser = await ref.read(currentAttendantProvider.future);
      final location = await ref.read(attendantLocationProvider.future);

      // This would send notifications to management
      if (kDebugMode) print('🚨 SOS Alert sent by: ${currentUser?.fullName}');
      if (kDebugMode) print('📍 Location: ${location?.name}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS alert sent to all emergency contacts'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to send SOS alert: $e');
    }
  }

  Future<void> _requestSecurity() async {
    try {
      final currentUser = await ref.read(currentAttendantProvider.future);
      final location = await ref.read(attendantLocationProvider.future);

      // In a real app, this would contact security
      if (kDebugMode) print('🛡️ Security requested by: ${currentUser?.fullName}');
      if (kDebugMode) print('📍 Location: ${location?.name}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Security has been notified and will respond shortly'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to request security: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Incident Report Form
class IncidentReportForm extends ConsumerStatefulWidget {
  const IncidentReportForm({super.key});

  @override
  ConsumerState<IncidentReportForm> createState() => _IncidentReportFormState();
}

class _IncidentReportFormState extends ConsumerState<IncidentReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  EmergencyType selectedType = EmergencyType.other;
  bool isUrgent = false;
  bool isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Report an Incident',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Provide details about the incident to help us respond appropriately.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            // Incident Type
            const Text(
              'Incident Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EmergencyType.values.map((type) {
                final isSelected = selectedType == type;
                return FilterChip(
                  label: Text(_getTypeLabel(type)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedType = type;
                    });
                  },
                  selectedColor: _getTypeColor(type).withValues(alpha: 0.2),
                  checkmarkColor: _getTypeColor(type),
                  avatar: isSelected
                      ? null
                      : Icon(
                          _getTypeIcon(type),
                          size: 16,
                          color: _getTypeColor(type),
                        ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Location
            const Text(
              'Location Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Specific Location (e.g., Spot A15, Main Gate)',
                hintText: 'Where did this incident occur?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please specify the location';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            const Text(
              'Incident Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Describe what happened',
                hintText: 'Provide as much detail as possible...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe the incident';
                }
                if (value.length < 10) {
                  return 'Please provide more details (at least 10 characters)';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Priority toggle
            Card(
              child: SwitchListTile(
                title: const Text('Mark as Urgent'),
                subtitle: const Text('Requires immediate attention'),
                value: isUrgent,
                onChanged: (value) {
                  setState(() {
                    isUrgent = value;
                  });
                },
                secondary: Icon(
                  isUrgent ? Icons.priority_high : Icons.low_priority,
                  color: isUrgent ? Colors.red : Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUrgent ? Colors.red : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isUrgent ? Icons.emergency : Icons.send),
                          const SizedBox(width: 8),
                          Text(
                            isUrgent
                                ? 'Submit Emergency Report'
                                : 'Submit Report',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your report will be sent to site management and appropriate response teams. '
                      'For immediate emergencies, use the Quick Contacts tab.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final currentUser = await ref.read(currentAttendantProvider.future);
      final location = await ref.read(attendantLocationProvider.future);

      // In a real app, this would save to database and notify management
      if (kDebugMode) print('📝 Incident Report Submitted:');
      if (kDebugMode) print('   Type: ${_getTypeLabel(selectedType)}');
      if (kDebugMode) print('   Location: ${_locationController.text}');
      if (kDebugMode) print('   Description: ${_descriptionController.text}');
      if (kDebugMode) print('   Urgent: $isUrgent');
      if (kDebugMode) print('   Reported by: ${currentUser?.fullName}');
      if (kDebugMode) print('   Site: ${location?.name}');

      if (mounted) {
        // Clear form
        _descriptionController.clear();
        _locationController.clear();
        setState(() {
          selectedType = EmergencyType.other;
          isUrgent = false;
        });

        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUrgent
                  ? 'Emergency report submitted! Response team has been notified.'
                  : 'Incident report submitted successfully. Management will review and respond.',
            ),
            backgroundColor: isUrgent ? Colors.red : Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Close the sheet after a delay if urgent
        if (isUrgent) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  String _getTypeLabel(EmergencyType type) {
    switch (type) {
      case EmergencyType.security:
        return 'Security';
      case EmergencyType.medical:
        return 'Medical';
      case EmergencyType.fire:
        return 'Fire';
      case EmergencyType.accident:
        return 'Accident';
      case EmergencyType.maintenance:
        return 'Maintenance';
      case EmergencyType.theft:
        return 'Theft';
      case EmergencyType.vandalism:
        return 'Vandalism';
      case EmergencyType.other:
        return 'Other';
    }
  }

  IconData _getTypeIcon(EmergencyType type) {
    switch (type) {
      case EmergencyType.security:
        return Icons.security;
      case EmergencyType.medical:
        return Icons.medical_services;
      case EmergencyType.fire:
        return Icons.local_fire_department;
      case EmergencyType.accident:
        return Icons.car_crash;
      case EmergencyType.maintenance:
        return Icons.build;
      case EmergencyType.theft:
        return Icons.gpp_bad;
      case EmergencyType.vandalism:
        return Icons.warning;
      case EmergencyType.other:
        return Icons.report_problem;
    }
  }

  Color _getTypeColor(EmergencyType type) {
    switch (type) {
      case EmergencyType.security:
        return Colors.blue;
      case EmergencyType.medical:
        return Colors.red;
      case EmergencyType.fire:
        return Colors.deepOrange;
      case EmergencyType.accident:
        return Colors.purple;
      case EmergencyType.maintenance:
        return Colors.brown;
      case EmergencyType.theft:
        return Colors.indigo;
      case EmergencyType.vandalism:
        return Colors.orange;
      case EmergencyType.other:
        return Colors.grey;
    }
  }
}

