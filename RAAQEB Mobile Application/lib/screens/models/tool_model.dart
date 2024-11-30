import 'package:cloud_firestore/cloud_firestore.dart';

// models/tool_model.dart
class Tool {
  final String id; // Add id field
  final String name;
  final String location;
  final String roomId;
  final DateTime expirationDate;
  final DateTime maintenanceDate;
  final DateTime lastUpdate;

  Tool({
    required this.id, // Add id to constructor
    required this.name,
    required this.location,
    required this.roomId,
    required this.expirationDate,
    required this.maintenanceDate,
    required this.lastUpdate,
  });

  factory Tool.fromMap(Map<String, dynamic> data, {String? id}) {
    return Tool(
      id: id ?? '', // Include document ID
      name: data['name'] ?? 'Unnamed Tool',
      location: data['location'] ?? '',
      roomId: data['roomId'] ?? '',
      expirationDate: (data['expirationDate'] as Timestamp).toDate(),
      maintenanceDate: (data['maintenanceDate'] as Timestamp).toDate(),
      lastUpdate: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'roomId': roomId,
      'expirationDate': Timestamp.fromDate(expirationDate),
      'maintenanceDate': Timestamp.fromDate(maintenanceDate),
      'timestamp': Timestamp.fromDate(lastUpdate),
    };
  }
}