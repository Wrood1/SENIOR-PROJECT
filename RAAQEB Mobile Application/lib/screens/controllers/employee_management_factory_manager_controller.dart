import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/employee_management_factory_manager_model.dart';

class FactoryManagementController {
  final String factoryManagerId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _baseUrl = 'https://smart-64616-default-rtdb.firebaseio.com';
  
  FactoryManagementController({required this.factoryManagerId});

  // Helper method to find location by factory manager ID
  Future<String?> _findLocationId() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/.json'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> locations = json.decode(response.body);
        String? locationId;
        
        locations.forEach((key, value) {
          if (value['ID'] == factoryManagerId) {
            locationId = key;
          }
        });
        
        return locationId;
      }
      return null;
    } catch (e) {
      print('Error finding location: $e');
      return null;
    }
  }

  // Helper method to update phones in location
  Future<void> _updateLocationPhones(String locationId, String phone, bool isAdding, String position, String userId) async {
    try {
      // Get current phones
      final response = await http.get(
        Uri.parse('$_baseUrl/$locationId/phone_numbers.json')
      );
      
      Map<String, dynamic> phones = {};
      if (response.statusCode == 200 && response.body != 'null') {
        phones = Map<String, dynamic>.from(json.decode(response.body));
      }

      if (isAdding) {
        // Create a unique key using position and userId
        String uniqueKey = '${position}_$userId';
        phones[uniqueKey] = phone;
      } else {
        // Remove the specific phone entry for this user
        phones.removeWhere((key, value) => 
          value == phone && key.startsWith('${position}_'));
      }

      // Save updated phones map
      final updateResponse = await http.put(
        Uri.parse('$_baseUrl/$locationId/phone_numbers.json'),
        body: json.encode(phones)
      );

      if (updateResponse.statusCode != 200) {
        throw Exception('Failed to update phones');
      }
    } catch (e) {
      print('Error updating phones: $e');
      rethrow;
    }
  }

  Future<List<Person>> loadPersonsByPosition(String position) async {
    final QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('position', isEqualTo: position)
        .where('factoryManagerId', isEqualTo: factoryManagerId)
        .get();

    return querySnapshot.docs
        .map((doc) => Person.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> addPerson(String email, String position, BuildContext context) async {
    try {
      // Find user in Firestore
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data() as Map<String, dynamic>;
      final String userId = userDoc.id;  // Get the user's document ID

      if (userData['factoryManagerId'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('This user is already assigned to another factory manager')),
        );
        return;
      }

      // Get user's phone number
      String? phone = userData['phone'];
      if (phone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User does not have a registered phone number')),
        );
        return;
      }

      // Find associated location
      String? locationId = await _findLocationId();
      if (locationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factory location not found')),
        );
        return;
      }

      // Update Firestore user
      await userDoc.reference.update({
        'factoryManagerId': factoryManagerId,
        'position': position,
      });

      // Add phone to location's phones list using HTTP
      await _updateLocationPhones(locationId, phone, true, position, userId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$position added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding person: $e')),
      );
    }
  }

  Future<void> deletePerson(String userId, BuildContext context) async {
    try {
      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      String? phone = userData['phone'];
      String? position = userData['position'];

      if (phone != null && position != null) {
        // Find associated location
        String? locationId = await _findLocationId();
        if (locationId != null) {
          // Remove phone from location's phones list using HTTP
          await _updateLocationPhones(locationId, phone, false, position, userId);
        }
      }

      // Update Firestore user
      await _firestore.collection('users').doc(userId).update({
        'factoryManagerId': null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Person removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing person: $e')),
      );
    }
  }

  // Method to get all phone numbers for a location
  Future<Map<String, String>> getPhoneNumbers() async {
    try {
      String? locationId = await _findLocationId();
      if (locationId == null) {
        return {};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/$locationId/phone_numbers.json')
      );
      
      if (response.statusCode == 200 && response.body != 'null') {
        return Map<String, String>.from(json.decode(response.body));
      }
      
      return {};
    } catch (e) {
      print('Error getting phone numbers: $e');
      return {};
    }
  }
}