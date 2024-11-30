import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../utils/colors.dart';
import '../utils/colors.dart';
import '../models/location_management_model.dart';
import '../controllers/location_management_controller.dart';

class LocationManagementPage extends StatefulWidget {
  const LocationManagementPage({super.key});

  @override
  _LocationManagementPageState createState() => _LocationManagementPageState();
}

class _LocationManagementPageState extends State<LocationManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  
  final LocationController _controller = LocationController();
  
  List<Room> _rooms = [];
  final List<Room> _existingRooms = [];
  Room? _selectedExistingRoom;
  
  bool _isLoading = false;
  String? _existingLocationId;
  
  double? _latitude;
  double? _longitude;
  
  bool _showNewRoomForm = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    setState(() => _isLoading = true);
    
    // Get current location
    Position? position = await _controller.getCurrentLocation();
    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    }

    // Load existing location
    Map<String, dynamic>? locationData = await _controller.loadExistingLocation();
    if (locationData != null) {
      setState(() {
        _existingLocationId = locationData['locationId'];
        _locationNameController.text = locationData['locationData']['name'] ?? '';
        _phoneNumberController.text = locationData['locationData']['phone_number'] ?? '';
        
        _existingRooms.clear();
        locationData['locationData'].forEach((roomKey, roomValue) {
          if (roomKey.startsWith('room')) {
            Room room = Room(id: roomKey);
            room.level = roomValue['level'] ?? 1;
            room.name = roomValue['name'] ?? '';
            
            roomValue.forEach((sensorKey, sensorValue) {
              if (sensorKey != 'ID' && sensorKey != 'name' && sensorKey != 'level') {
                String type = _controller.availableSensorTypes.firstWhere(
                  (t) => sensorKey.startsWith(t),
                  orElse: () => '',
                );
                
                if (type.isNotEmpty) {
                  if (!room.sensorsByType.containsKey(type)) {
                    room.sensorsByType[type] = [];
                  }
                  room.sensorsByType[type]!.add(sensorKey);
                  room.sensorValues[sensorKey] = sensorValue.toString();
                }
              }
            });
            _existingRooms.add(room);
          }
        });
      });
    }

    setState(() => _isLoading = false);
  }

  void _addNewRoom() {
    setState(() {
      _rooms = _controller.addNewRoom(_existingRooms, _rooms);
      _showNewRoomForm = true;
    });
  }

  void _removeRoom(int index) {
    setState(() {
      _rooms.removeAt(index);
      for (int i = 0; i < _rooms.length; i++) {
        _rooms[i].id = 'room${i + 1}';
      }
    });
  }

  void _addSensor(Room room, String type) {
    setState(() {
      room.addSensor(type);
      room.selectedSensorType = null;
    });
  }

  void _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      String? savedLocationId = await _controller.saveLocation(
        locationName: _locationNameController.text,
        phoneNumber: _phoneNumberController.text,
        latitude: _latitude,
        longitude: _longitude,
        existingRooms: _existingRooms,
        currentRooms: _rooms,
        existingLocationId: _existingLocationId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved successfully')),
      );
      
      setState(() {
        _existingLocationId = savedLocationId;
        _loadInitialData(); 
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving location: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildExistingRoomsDropdown() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Existing Rooms',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors().primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Room>(
            dropdownColor: Colors.white,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.room_preferences),
            ),
            value: _selectedExistingRoom,
            hint: const Text('Select an existing room'),
            items: _existingRooms.map((Room room) {
              return DropdownMenuItem<Room>(
                value: room,
                child: Text('${room.name} (Level ${room.level})'),
              );
            }).toList(),
            onChanged: (Room? newValue) {
              setState(() {
                _selectedExistingRoom = newValue;
                if (newValue != null) {
                  _rooms.clear();
                  _rooms.add(newValue);
                  _showNewRoomForm = true;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSensorsList(Room room) {
    List<Widget> sensorWidgets = [];

    room.sensorsByType.forEach((type, sensorIds) {
      for (String sensorId in sensorIds) {
        sensorWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '$sensorId Value',
                      border: const OutlineInputBorder(),
                      suffixText: type == 'fire' ? '(0/1)' : '',
                    ),
                    child: Text(room.sensorValues[sensorId] ?? '0'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => setState(() => room.removeSensor(sensorId)),
                ),
              ],
            ),
          ),
        );
      }
    });

    return Column(children: sensorWidgets);
  }

  Widget _buildAddSensorDropdown(Room room) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<String>(
        dropdownColor: Colors.white,
        decoration: const InputDecoration(
          labelText: 'Add Sensor',
          border: OutlineInputBorder(),
        ),
        value: room.selectedSensorType,
        hint: const Text('Select a sensor type'),
        items: _controller.availableSensorTypes.map((String type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              room.selectedSensorType = newValue;
              _addSensor(room, newValue);
            });
          }
        },
      ),
    );
  }

  Widget _buildRoomCard(Room room, int index) {
    int roomNumber = int.tryParse(room.id.replaceAll('room', '')) ?? (index + 1);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Room $roomNumber',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeRoom(index),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextFormField(
              initialValue: room.name,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.meeting_room),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a room name' : null,
              onSaved: (value) {
                room.name = value ?? '';
              },
            ),
            const SizedBox(height: 15),
            _buildSensorsList(room),
            _buildAddSensorDropdown(room),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: AppColors().primaryColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              _existingLocationId != null ? 'Edit Location' : 'Add Location',
              style: const TextStyle(
                fontSize: 19,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: _showLocationInfo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetails() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _locationNameController,
            decoration: InputDecoration(
              labelText: 'Location Name',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on, color: AppColors().primaryColor,),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _phoneNumberController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone, color: AppColors().primaryColor,),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a phone number' : null,
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Coordinates',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors().primaryColor,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.location_searching, size: 16, color: AppColors().primaryColor),
                    const SizedBox(width: 8),
                    Text('Latitude: ${_latitude?.toStringAsFixed(6) ?? "Loading..."}'),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.location_searching, size: 16, color: AppColors().primaryColor),
                    const SizedBox(width: 8),
                    Text('Longitude: ${_longitude?.toStringAsFixed(6) ?? "Loading..."}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors().primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _saveLocation,
        child: const Text(
          'Save Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color:Colors.white,
          ),
        ),
      ),
    );
  }

  void _showLocationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.brown),
            SizedBox(width: 10),
            Text('Location Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('• Each user can have only one location'),
            _buildInfoItem('• Each location can have multiple rooms'),
            _buildInfoItem('• Each room can have multiple sensors of the same type'),
            _buildInfoItem('• Sensor IDs are automatically numbered (e.g., gas1, gas2)'),
            _buildInfoItem('• Fire sensor values must be 0 or 1'),
            _buildInfoItem('• Each room must have a level (1, 2, or 3)'),
            _buildInfoItem('• Location data will be stored in Firebase'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
