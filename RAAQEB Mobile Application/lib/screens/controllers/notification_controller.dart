import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification_model.dart';

class NotificationController {
  final String userId;
  String? factoryManagerId;

  NotificationController({required this.userId});

  Future<void> fetchUserRole() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        factoryManagerId = userData?['factoryManagerId']?.toString();
      }
    } catch (e) {
      print('Error fetching user role: $e');
      throw Exception('Failed to fetch user role');
    }
  }

  Future<LocationModel?> fetchLocationData() async {
    try {
      final url =
          Uri.parse('https://smart-64616-default-rtdb.firebaseio.com/.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        for (var entry in data.entries) {
          if (entry.value is Map<String, dynamic>) {
            final locationData = entry.value as Map<String, dynamic>;

            if (hasAccessToLocation(locationData)) {
              return LocationModel.fromMap(locationData, entry.key);
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Error fetching location data: $e');
      throw Exception('Failed to fetch location data');
    }
  }

  bool hasAccessToLocation(Map<String, dynamic> locationData) {
    String locationId = locationData['ID']?.toString() ?? '';
    String currentUserId = userId.toString();
    String? currentManagerId = factoryManagerId?.toString();

    return currentUserId == locationId ||
        (currentManagerId != null && locationId == currentManagerId);
  }

  List<NotificationModel> buildNotificationsList(LocationModel location) {
    final notifications = <NotificationModel>[];
    final roomsByLevel = _getRoomsByLevel(location);

    // Create notification for level 3 (danger) rooms
    if (roomsByLevel[3]?.isNotEmpty ?? false) {
      notifications.add(
        NotificationModel(
          type: 'serious',
          title: '${location.name} - Serious Danger',
          message:
              'Serious danger detected in rooms: ${roomsByLevel[3]!.join(", ")}',
          timestamp: DateTime.now().toString(),
          level: 3,
        ),
      );
    }

    // Create notification for level 2 (medium) rooms
    if (roomsByLevel[2]?.isNotEmpty ?? false) {
      notifications.add(
        NotificationModel(
          type: 'medium',
          title: '${location.name} - Medium Risk',
          message:
              'Medium risk detected in rooms: ${roomsByLevel[2]!.join(", ")}',
          timestamp: DateTime.now().toString(),
          level: 2,
        ),
      );
    }

    // Sort notifications by level (highest first) and then by timestamp
    notifications.sort((a, b) {
      final levelCompare = b.level.compareTo(a.level);
      if (levelCompare != 0) return levelCompare;
      return b.timestamp.compareTo(a.timestamp);
    });

    return notifications;
  }

  Map<int, List<String>> _getRoomsByLevel(LocationModel location) {
    final Map<int, List<String>> roomsByLevel = {
      2: [],
      3: [],
    };

    location.rooms.forEach((roomName, roomData) {
      if (roomData is Map) {
        final roomMap = Map<String, dynamic>.from(roomData);
        final level = int.tryParse(roomMap['level']?.toString() ?? '0') ?? 0;

        // Only collect rooms with level 2 or 3
        if (level == 2 || level == 3) {
          roomsByLevel[level]!.add(roomName);
        }
      }
    });

    return roomsByLevel;
  }
}
