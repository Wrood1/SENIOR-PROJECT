import 'package:firebase_database/firebase_database.dart';
import '../models/configuration_settings_model.dart';

class ConfigurationController {
  final String userId;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  Map<String, RoomConfiguration> roomConfigs = {};
  Map<String, String> roomNames = {};
  List<String> rooms = [];

  ConfigurationController(this.userId);

  Future<void> loadRooms() async {
    try {
      final snapshot = await _database.get();
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        data.forEach((locationKey, locationData) {
          if (locationData is Map) {
            final locationMap = Map<String, dynamic>.from(locationData);
            if (locationMap['ID'] == userId) {
              locationMap.forEach((key, value) {
                if (key.startsWith('room') && value is Map) {
                  rooms.add(key);
                  roomNames[key] = (value['name'] as String?) ?? key;
                  roomConfigs[key] = RoomConfiguration.initial();
                }
              });
            }
          }
        });
      }
    } catch (e) {
      print('Error loading rooms: $e');
    }
  }

  void updatePriority(String room, String field, int value) {
    roomConfigs[room]?.priorities[field] = value;
  }

  void updateThresholds(String room, String field, String type, double value) {
    roomConfigs[room]?.thresholds[field][type] = value;
  }

  Future<bool> saveConfiguration(String selectedRoom) async {
    try {
      final snapshot = await _database.get();
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        data.forEach((locationKey, locationData) {
          if (locationData is Map) {
            final locationMap = Map<String, dynamic>.from(locationData);
            if (locationMap['ID'] == userId) {
              _database.child(locationKey).child(selectedRoom).update({
                'configuration': roomConfigs[selectedRoom]?.toJson(),
              });
            }
          }
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving configuration: $e');
      return false;
    }
  }
}