import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../providers/admin_providers.dart';

class LocationsManagementScreen extends ConsumerStatefulWidget {
  const LocationsManagementScreen({super.key});

  @override
  ConsumerState<LocationsManagementScreen> createState() =>
      _LocationsManagementScreenState();
}

class _LocationsManagementScreenState
    extends ConsumerState<LocationsManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(allParkingLocationsProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Management'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allParkingLocationsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search locations...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Locations List
          Expanded(
            child: locationsAsync.when(
              data: (locations) => usersAsync.when(
                data: (users) => _buildLocationsList(locations, users),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Error loading users: $error')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading locations: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(allParkingLocationsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateLocationDialog(),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add_location),
      ),
    );
  }

  Widget _buildLocationsList(
      List<ParkingLocation> allLocations, List<User> users) {
    // Filter locations by search query
    List<ParkingLocation> filteredLocations = allLocations;

    if (_searchQuery.isNotEmpty) {
      filteredLocations = allLocations
          .where((location) =>
              location.name.toLowerCase().contains(_searchQuery) ||
              location.address.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (filteredLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No parking locations found'
                  : 'No locations match your search',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredLocations.length,
      itemBuilder: (context, index) {
        final location = filteredLocations[index];
        final attendant =
            users.where((u) => u.id == location.attendantId).firstOrNull;
        return _buildLocationCard(location, attendant);
      },
    );
  }

  Widget _buildLocationCard(ParkingLocation location, User? attendant) {
    final occupancyRate = location.totalSpots > 0
        ? ((location.totalSpots - location.availableSpots) /
            location.totalSpots *
            100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            location.isActive
                                ? Icons.location_on
                                : Icons.location_off,
                            color:
                                location.isActive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location.address,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                      onTap: () => _showEditLocationDialog(location),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(location.isActive
                              ? Icons.block
                              : Icons.check_circle),
                          const SizedBox(width: 8),
                          Text(location.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                      onTap: () => _toggleLocationStatus(location),
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      onTap: () => _showDeleteLocationDialog(location),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    'Total Spots',
                    location.totalSpots.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    'Available',
                    location.availableSpots.toString(),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    'Occupancy',
                    '${occupancyRate.toStringAsFixed(0)}%',
                    occupancyRate > 80 ? Colors.red : Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    'Rate',
                    location.formattedHourlyRate,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Attendant Info
            if (attendant != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assigned Attendant',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            attendant.fullName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            attendant.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'No attendant assigned',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Additional Info
            if (location.description != null &&
                location.description!.isNotEmpty) ...[
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(location.description!),
              const SizedBox(height: 8),
            ],

            // Amenities
            if (location.amenities != null &&
                location.amenities!.isNotEmpty) ...[
              Text(
                'Amenities',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: location.amenities!
                    .map(
                      (amenity) => Chip(
                        label: Text(
                          amenity,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.grey[200],
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateLocationDialog(),
    ).then((_) {
      ref.invalidate(allParkingLocationsProvider);
    });
  }

  void _showEditLocationDialog(ParkingLocation location) {
    showDialog(
      context: context,
      builder: (context) => EditLocationDialog(location: location),
    ).then((_) {
      ref.invalidate(allParkingLocationsProvider);
    });
  }

  void _toggleLocationStatus(ParkingLocation location) async {
    try {
      final updatedLocation = location.copyWith(isActive: !location.isActive);
      final result =
          await ref.read(updateParkingLocationProvider(updatedLocation).future);

      if (result) {
        ref.invalidate(allParkingLocationsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location ${location.isActive ? 'deactivated' : 'activated'} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update location status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteLocationDialog(ParkingLocation location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete ${location.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement location deletion
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location deletion not implemented yet'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Create Location Dialog
class CreateLocationDialog extends ConsumerStatefulWidget {
  const CreateLocationDialog({super.key});

  @override
  ConsumerState<CreateLocationDialog> createState() =>
      _CreateLocationDialogState();
}

class _CreateLocationDialogState extends ConsumerState<CreateLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _totalSpotsController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amenitiesController = TextEditingController();
  String? _selectedAttendantId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _totalSpotsController.dispose();
    _hourlyRateController.dispose();
    _descriptionController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendantsAsync = ref.watch(usersByRoleProvider('attendant'));

    return AlertDialog(
      title: const Text('Create New Location'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter location name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter latitude';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter longitude';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _totalSpotsController,
                        decoration: const InputDecoration(
                          labelText: 'Total Spots',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter total spots';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _hourlyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Hourly Rate (ETB)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter hourly rate';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                attendantsAsync.when(
                  data: (attendants) => DropdownButtonFormField<String>(
                    value: _selectedAttendantId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Attendant (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No attendant'),
                      ),
                      ...attendants.map(
                        (attendant) => DropdownMenuItem<String>(
                          value: attendant.id,
                          child: Text(attendant.fullName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAttendantId = value;
                      });
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading attendants'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amenitiesController,
                  decoration: const InputDecoration(
                    labelText: 'Amenities (comma separated)',
                    border: OutlineInputBorder(),
                    hintText: 'Security, CCTV, Well-lit',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createLocation,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final totalSpots = int.parse(_totalSpotsController.text);
      final amenities = _amenitiesController.text.trim().isEmpty
          ? <String>[]
          : _amenitiesController.text.split(',').map((e) => e.trim()).toList();

      final locationData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': double.parse(_latitudeController.text),
        'longitude': double.parse(_longitudeController.text),
        'totalSpots': totalSpots,
        'availableSpots': totalSpots, // Initially all spots are available
        'hourlyRate': double.parse(_hourlyRateController.text),
        'isActive': true,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'amenities': amenities,
        'attendantId': _selectedAttendantId,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final result =
          await ref.read(createParkingLocationProvider(locationData).future);

      if (result != null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create location'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Edit Location Dialog - Similar to Create but with pre-filled data
class EditLocationDialog extends ConsumerStatefulWidget {
  final ParkingLocation location;

  const EditLocationDialog({super.key, required this.location});

  @override
  ConsumerState<EditLocationDialog> createState() => _EditLocationDialogState();
}

class _EditLocationDialogState extends ConsumerState<EditLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _totalSpotsController;
  late TextEditingController _availableSpotsController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _descriptionController;
  late TextEditingController _amenitiesController;
  late String? _selectedAttendantId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location.name);
    _addressController = TextEditingController(text: widget.location.address);
    _totalSpotsController =
        TextEditingController(text: widget.location.totalSpots.toString());
    _availableSpotsController =
        TextEditingController(text: widget.location.availableSpots.toString());
    _hourlyRateController =
        TextEditingController(text: widget.location.hourlyRate.toString());
    _descriptionController =
        TextEditingController(text: widget.location.description ?? '');
    _amenitiesController = TextEditingController(
      text: widget.location.amenities?.join(', ') ?? '',
    );
    _selectedAttendantId = widget.location.attendantId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _totalSpotsController.dispose();
    _availableSpotsController.dispose();
    _hourlyRateController.dispose();
    _descriptionController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendantsAsync = ref.watch(usersByRoleProvider('attendant'));

    return AlertDialog(
      title: Text('Edit ${widget.location.name}'),
      content: SizedBox(
        width: 500,
        height: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter location name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _totalSpotsController,
                        decoration: const InputDecoration(
                          labelText: 'Total Spots',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter total spots';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _availableSpotsController,
                        decoration: const InputDecoration(
                          labelText: 'Available Spots',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter available spots';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _hourlyRateController,
                  decoration: const InputDecoration(
                    labelText: 'Hourly Rate (ETB)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter hourly rate';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                attendantsAsync.when(
                  data: (attendants) => DropdownButtonFormField<String>(
                    value: _selectedAttendantId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Attendant',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No attendant'),
                      ),
                      ...attendants.map(
                        (attendant) => DropdownMenuItem<String>(
                          value: attendant.id,
                          child: Text(attendant.fullName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAttendantId = value;
                      });
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading attendants'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amenitiesController,
                  decoration: const InputDecoration(
                    labelText: 'Amenities (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateLocation,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amenities = _amenitiesController.text.trim().isEmpty
          ? <String>[]
          : _amenitiesController.text.split(',').map((e) => e.trim()).toList();

      final updatedLocation = widget.location.copyWith(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        totalSpots: int.parse(_totalSpotsController.text),
        availableSpots: int.parse(_availableSpotsController.text),
        hourlyRate: double.parse(_hourlyRateController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        amenities: amenities,
        attendantId: _selectedAttendantId,
        updatedAt: DateTime.now(),
      );

      final result =
          await ref.read(updateParkingLocationProvider(updatedLocation).future);

      if (result) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update location'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
