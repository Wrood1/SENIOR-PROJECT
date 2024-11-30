import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/factory_manager_alerts_model.dart';
import '../controllers/factory_manager_alerts_controller.dart';
import '../../utils/colors.dart';

class SafetyPersonBroadcastsPage extends StatelessWidget {
  final String userId;
  final BroadcastController controller = BroadcastController();

  SafetyPersonBroadcastsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors().backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors().primaryColor,
          centerTitle: true,
          leading: IconButton(onPressed: ()=> Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white,)),
          elevation: 0,
          title: const Text(
            'Broadcasts', 
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Completed'),
            ],
            indicatorColor: Colors.white,
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildBroadcastList(false),
            _buildBroadcastList(true),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastList(bool isCompleted) {
    return StreamBuilder<DocumentSnapshot>(
      stream: controller.getUserStream(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          controller.logError('user stream', userSnapshot.error, userSnapshot.stackTrace);
          return Center(
            child: Text(
              'Error loading user data: ${userSnapshot.error}',
              style: TextStyle(color: AppColors().primaryColor),
            ),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors().primaryColor),
            ),
          );
        }

        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
        String? userFactoryManagerId = userData['factoryManagerId'];

        if (userFactoryManagerId == null) {
          return Center(
            child: Text(
              'User factory manager ID not found',
              style: TextStyle(color: AppColors().primaryColor),
            ),
          );
        }

        return _buildBroadcastStreamBuilder(isCompleted, userFactoryManagerId);
      },
    );
  }

  Widget _buildBroadcastStreamBuilder(bool isCompleted, String factoryManagerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.getBroadcastsStream(isCompleted, factoryManagerId),
      builder: (context, broadcastSnapshot) {
        if (broadcastSnapshot.hasError) {
          controller.logError('broadcasts stream', broadcastSnapshot.error, broadcastSnapshot.stackTrace);
          return Center(
            child: Text(
              'Error loading broadcasts: ${broadcastSnapshot.error}',
              style: TextStyle(color: AppColors().primaryColor),
            ),
          );
        }

        if (!broadcastSnapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors().primaryColor),
            ),
          );
        }

        if (broadcastSnapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              isCompleted ? 'No completed broadcasts' : 'No pending broadcasts',
              style: TextStyle(
                fontSize: 16,
                color: AppColors().primaryColor,
              ),
            ),
          );
        }

        return _buildBroadcastListView(broadcastSnapshot.data!.docs, isCompleted);
      },
    );
  }

  Widget _buildBroadcastListView(List<QueryDocumentSnapshot> broadcasts, bool isCompleted) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: broadcasts.length,
      itemBuilder: (context, index) {
        try {
          var broadcast = Broadcast.fromFirestore(broadcasts[index]);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.grey.shade100,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                broadcast.message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors().primaryColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${broadcast.status}',
                    style: TextStyle(color: AppColors().primaryColor.withOpacity(0.8)),
                  ),
                  if (broadcast.completedBy != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: controller.getCompletedByUser(broadcast.completedBy!),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.hasError) {
                          return Text(
                            'Error loading user info',
                            style: TextStyle(color: AppColors().primaryColor.withOpacity(0.8)),
                          );
                        }
                        if (!userSnapshot.hasData) {
                          return Text(
                            'Loading user info...',
                            style: TextStyle(color: AppColors().primaryColor.withOpacity(0.8)),
                          );
                        }
                        
                        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        return Text(
                          'Completed by: ${userData['name'] ?? 'Unknown user'}',
                          style: TextStyle(color: AppColors().primaryColor.withOpacity(0.8)),
                        );
                      },
                    ),
                  if (broadcast.completedAt != null)
                    Text(
                      'Completed at: ${broadcast.completedAt}',
                      style: TextStyle(color: AppColors().primaryColor.withOpacity(0.8)),
                    ),
                  if (broadcast.response != null)
                    Text(
                      'Response: ${broadcast.response}',
                      style: TextStyle(color: AppColors().primaryColor.withOpacity(0.8)),
                    ),
                ],
              ),
              trailing: !isCompleted
                  ? IconButton(
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: AppColors().primaryColor,
                        size: 28,
                      ),
                      onPressed: () => _showCompleteDialog(
                        context,
                        broadcast.id,
                      ),
                    )
                  : null,
            ),
          );
        } catch (e, stackTrace) {
          controller.logError('building list item', e, stackTrace);
          return ListTile(
            title: Text(
              'Error loading broadcast item: $e',
              style: TextStyle(color: AppColors().primaryColor),
            ),
          );
        }
      },
    );
  }

  void _showCompleteDialog(BuildContext context, String broadcastId) {
    final TextEditingController responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade100,
          title: Text(
            'Complete Broadcast',
            style: TextStyle(color: AppColors().primaryColor),
          ),
          content: TextField(
            controller: responseController,
            decoration: InputDecoration(
              hintText: 'Enter your response...',
              hintStyle: TextStyle(color: AppColors().primaryColor.withOpacity(0.6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors().primaryColor),
              ),
            ),
            style: TextStyle(color: AppColors().primaryColor),
            maxLines: 3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors().primaryColor),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                'Complete',
                style: TextStyle(color: AppColors().primaryColor),
              ),
              onPressed: () => controller.completeBroadcast(
                broadcastId,
                userId,
                responseController.text,
                context,
              ),
            ),
          ],
        );
      },
    );
  }
}