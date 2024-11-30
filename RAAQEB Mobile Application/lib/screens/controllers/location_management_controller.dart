import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

import '../models/location_management_model.dart';

class LocationController {
  final List<String> availableSensorTypes = [
    'temp', 'humidity', 'gas', 'fire'
  ];

  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

  List<Room> addNewRoom(List<Room> existingRooms, List<Room> currentRooms) {
    int maxExistingRoomNumber = 0;
    
    for (var room in existingRooms) {
      int roomNumber = int.tryParse(room.id.replaceAll('room', '')) ?? 0;
      maxExistingRoomNumber = max(maxExistingRoomNumber, roomNumber);
    }
    
    for (var room in currentRooms) {
      int roomNumber = int.tryParse(room.id.replaceAll('room', '')) ?? 0;
      maxExistingRoomNumber = max(maxExistingRoomNumber, roomNumber);
    }
    
    int newRoomNumber = maxExistingRoomNumber + 1;
    Room newRoom = Room(id: 'room$newRoomNumber');
    newRoom.name = 'Room $newRoomNumber';
    
    return [...currentRooms, newRoom];
  }

  Future<Map<String, dynamic>?> loadExistingLocation() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    DatabaseEvent event = await ref.once();

    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> locations = event.snapshot.value as Map;
      for (var entry in locations.entries) {
        if (entry.value['ID'] == userId) {
          return {
            'locationId': entry.key,
            'locationData': entry.value
          };
        }
      }
    }
    return null;
  }

  Future<String> saveLocation({
    required String locationName,
    required String phoneNumber,
    required double? latitude,
    required double? longitude,
    required List<Room> existingRooms,
    required List<Room> currentRooms,
    String? existingLocationId,
  }) async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      String locationId = existingLocationId ?? 'location${DateTime.now().millisecondsSinceEpoch}';

      Map<String, dynamic> locationData = {
        'ID': userId,
        'name': locationName,
        'phone_number': phoneNumber,
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'alarm': '0',
      };

      // Save existing rooms that weren't modified
      for (var room in existingRooms) {
        if (!currentRooms.contains(room)) {
          Map<String, dynamic> roomData = {
            'ID': room.level,
            'level': room.level,
            'name': room.name,
          };
          roomData.addAll(room.sensorValues);
          locationData[room.id] = roomData;
        }
      }

      // Save modified or new rooms
      for (var room in currentRooms) {
        Map<String, dynamic> roomData = {
          'ID': room.level,
          'level': room.level,
          'name': room.name,
        };
        roomData.addAll(room.sensorValues);
        locationData[room.id] = roomData;
      }

      DatabaseReference ref = FirebaseDatabase.instance.ref(locationId);
      await ref.set(locationData);

      return locationId;
    } catch (e) {
      print('Error saving location: $e');
      rethrow;
    }
  }
}