import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../providers/comprehensive_providers.dart';

class DatabaseDebugScreen extends ConsumerStatefulWidget {
  const DatabaseDebugScreen({super.key});

  @override
  ConsumerState<DatabaseDebugScreen> createState() => _DatabaseDebugScreenState();
}

class _DatabaseDebugScreenState extends ConsumerState<DatabaseDebugScreen> {
  bool _isLoading = false;
  final List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _runDatabaseTests();
  }

  Future<void> _runDatabaseTests() async {
    setState(() {
      _isLoading = true;
      _debugLogs.clear();
    });

    await _testDatabaseConnection();
    await _testParkingLocations();
    await _testUserData();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testDatabaseConnection() async {
    _addLog('🔍 Testing database connection...');
    
    try {
      final dbService = DatabaseService.instance;
      final isConnected = await dbService.isConnected();
      
      if (isConnected) {
        _addLog('✅ Database connection successful');
      } else {
        _addLog('❌ Database connection failed');
      }
    } catch (e) {
      _addLog('❌ Database connection error: $e');
    }
  }

  Future<void> _testParkingLocations() async {
    _addLog('🅿️ Testing parking locations...');
    
    try {
      final dbService = DatabaseService.instance;
      final locations = await dbService.getAllParkingLocations();
      
      _addLog('📋 Found ${locations.length} parking locations:');
      
      if (locations.isEmpty) {
        _addLog('⚠️ No parking locations found in database');
        _addLog('💡 Make sure you have added parking locations to your Appwrite database');
        _addLog('📍 Database: wepark_db, Collection: parking_locations');
      } else {
        for (var location in locations) {
          _addLog('   • ${location.name} - ${location.availableSpots}/${location.totalSpots} spots - ${location.formattedHourlyRate}');
        }
      }
    } catch (e) {
      _addLog('❌ Error fetching parking locations: $e');
      _addLog('💡 Check your Appwrite console for proper database setup');
    }
  }

  Future<void> _testUserData() async {
    _addLog('👤 Testing user data...');
    
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      
      if (currentUser != null) {
        _addLog('✅ Current user: ${currentUser.fullName} (${currentUser.email})');
        _addLog('🚗 Vehicle: ${currentUser.vehiclePlateNumber ?? 'Not set'}');
        _addLog('📱 Phone: ${currentUser.phoneNumber ?? 'Not set'}');
      } else {
        _addLog('⚠️ No current user found');
      }
    } catch (e) {
      _addLog('❌ Error fetching user data: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _debugLogs.add('${DateTime.now().toString().substring(11, 19)} $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Database Debug',
          style: TextStyle(
            color: Colors.green,
            fontFamily: 'monospace',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _runDatabaseTests,
            icon: const Icon(Icons.refresh, color: Colors.green),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Row(
              children: [
                Icon(
                  _isLoading ? Icons.sync : Icons.check_circle,
                  color: _isLoading ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  _isLoading ? 'Running tests...' : 'Tests completed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          
          // Debug logs
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: _debugLogs.length,
                itemBuilder: (context, index) {
                  final log = _debugLogs[index];
                  Color textColor = Colors.green;
                  
                  if (log.contains('❌')) {
                    textColor = Colors.red;
                  } else if (log.contains('⚠️')) {
                    textColor = Colors.orange;
                  } else if (log.contains('💡')) {
                    textColor = Colors.blue;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Quick actions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Appwrite console
                      _addLog('💡 Open your Appwrite console to check database setup');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Appwrite Console'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate back to app
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Back to App'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
