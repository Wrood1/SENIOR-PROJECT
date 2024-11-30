// views/tools_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartsavior2/utils/colors.dart';
import '../controllers/tools_controller.dart';
import '../models/tool_model.dart';
import '../../widgets/bottom_bar.dart';
import 'notifications_page.dart';

class ToolsView extends StatefulWidget {
  final String userId;

  const ToolsView({
    super.key,
    required this.userId,
  });

  @override
  _ToolsViewState createState() => _ToolsViewState();
}

class _ToolsViewState extends State<ToolsView> with SingleTickerProviderStateMixin {
  late ToolsController _controller;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  
  Tool? selectedTool;
  String _name = '';
  String? _selectedLocation;
  String? _selectedRoomId;
  DateTime? _maintenanceDate;
  DateTime? _expirationDate;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = ToolsController(userId: widget.userId);
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    await _controller.initialize();
    setState(() => _isLoading = false);
  }

  void _handleBack() {
    Navigator.of(context).pop();
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsPage(userId: widget.userId),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isMaintenanceDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    
    if (picked != null) {
      setState(() {
        if (isMaintenanceDate) {
          _maintenanceDate = picked;
        } else {
          _expirationDate = picked;
        }
      });
    }
  }

  void _resetForm() {
    setState(() {
      _name = '';
      _selectedLocation = null;
      _selectedRoomId = null;
      _maintenanceDate = null;
      _expirationDate = null;
      _formKey.currentState?.reset();
    });
  }

  void _submitNewTool() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      await _controller.addTool(
        name: _name,
        location: _selectedLocation!,
        roomId: _selectedRoomId!,
        maintenanceDate: _maintenanceDate!,
        expirationDate: _expirationDate!,
      );

      _tabController.animateTo(0);
      _resetForm();
    }
  }

  void _showEditDialog(Tool tool) {
    print('Available rooms for location ${tool.location}: ${_controller.locationRooms[tool.location]}');
    String updatedName = tool.name;
  String? updatedRoomId = tool.roomId;
  DateTime? updatedMaintenanceDate = tool.maintenanceDate;
  DateTime? updatedExpirationDate = tool.expirationDate;
    
    // Create a StatefulBuilder to handle state changes within the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Tool'),
              content: SingleChildScrollView(
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: tool.name,
                        decoration: InputDecoration(
                          labelText: 'Tool Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onChanged: (value) => updatedName = value,
                      ),
                      const SizedBox(height: 16),
                      // Updated DropdownButtonFormField with proper room data
                      DropdownButtonFormField<String>(
  value: updatedRoomId,
  decoration: InputDecoration(
    labelText: 'Room',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
    ),
  ),
  items: _controller.locationRooms[tool.location]?.entries.map((entry) {
    return DropdownMenuItem(
      value: entry.key,
      child: Text(entry.value),
    );
  }).toList() ?? [],
  onChanged: (String? value) {
    setState(() {
      updatedRoomId = value;
    });
  },
),
                      const SizedBox(height: 16),
                      // Date fields with visual feedback
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(15),
                        child: ListTile(
                          title: const Text('Maintenance Date'),
                          subtitle: Text(
                            DateFormat('dd MMM yyyy').format(updatedMaintenanceDate ?? tool.maintenanceDate),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: updatedMaintenanceDate ?? tool.maintenanceDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );
                            if (date != null) {
                              setState(() {
                                updatedMaintenanceDate = date;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Material(
  elevation: 2,
  borderRadius: BorderRadius.circular(15),
  child: ListTile(
    title: const Text('Expiration Date'),
    subtitle: Text(
      DateFormat('dd MMM yyyy').format(updatedExpirationDate ?? tool.expirationDate),
    ),
    trailing: const Icon(Icons.calendar_today),
    onTap: () async {
      final date = await showDatePicker(
        context: context,
        initialDate: updatedExpirationDate ?? tool.expirationDate,
        firstDate: DateTime(2000), // Adjust as needed
        lastDate: DateTime(2101),
      );
      if (date != null) {
        setState(() {
          updatedExpirationDate = date;
        });
      }
    },
  ),
),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (updatedRoomId != null) {
                      await _controller.updateTool(
                        toolId: tool.id,
                        name: updatedName,
                        location: tool.location,
                        roomId: updatedRoomId!,
                        maintenanceDate: updatedMaintenanceDate ?? tool.maintenanceDate,
                        expirationDate: updatedExpirationDate ?? tool.expirationDate,
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors().primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_controller.userLocation == null) {
      return _buildNoAccessScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                if (_controller.canAddTools) _buildTabs(),
                Expanded(
                  child: _controller.canAddTools
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          selectedTool != null ? _buildToolDetail() : _buildToolsList(),
                          _buildAddNewTool(),
                        ],
                      )
                    : (selectedTool != null ? _buildToolDetail() : _buildToolsList()),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _handleBack,
        ),
        elevation: 0,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildNoAccessScreen() {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _handleBack,
        ),
        elevation: 0,
      ),
      body: const Center(child: Text('No access to any location')),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors().primaryColor,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _handleBack,
      ),
      elevation: 0,
      title: const Text(
        'Tools',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: const [
      ],
    );
  }

  Widget _buildTabs() {
    return Container(color: AppColors().primaryColor,
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Tools'),
          Tab(text: 'Add New'),
        ],
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.5),
        indicatorColor: AppColors().secondaryColor,
      ),
    );
  }

  Widget _buildToolsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Tools',
    prefixIcon: const Icon(Icons.search),
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
    ),),
            onChanged: (value) {
              setState(() {}); // Trigger rebuild to update search results
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Tool>>(
            stream: _controller.getToolsStream(_searchController.text),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final tools = snapshot.data!;
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tools.length,
                itemBuilder: (context, index) {
                  return _buildToolCard(tools[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  

  Widget _buildToolCard(Tool tool) {
    return Card(
      elevation: 5, // Adds a subtle shadow
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Adds spacing
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.95), // Slightly transparent white for a soft look
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            selectedTool = tool;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tool Icon or Placeholder Image
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.build, // Replace with a relevant icon or image
                  color: AppColors().primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16), // Spacing between icon and text
              // Tool Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tool.location} - Room ${tool.roomId}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Trailing Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolDetail() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 5, // Adds shadow for depth
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white.withOpacity(0.95),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tool Icon or Image
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors().primaryColor,
                ),
                child:  Icon(
                  Icons.construction,
                  size: 80,
                  color: AppColors().secondaryColor,
                ),
              ),
              const SizedBox(height: 20),
              // Tool Name
              Text(
                selectedTool!.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Tool Details
              Divider(color: Colors.grey[300], thickness: 1),
              _buildInfoRow('Location', selectedTool!.location),
              _buildInfoRow('Room ID', selectedTool!.roomId),
              _buildInfoRow(
                'Expiration Date',
                DateFormat('dd MMM yyyy').format(selectedTool!.expirationDate),
              ),
              _buildInfoRow(
                'Maintenance Date',
                DateFormat('dd MMM yyyy').format(selectedTool!.maintenanceDate),
              ),
              _buildInfoRow(
                'Last Update',
                DateFormat('dd MMM yyyy').format(selectedTool!.lastUpdate),
              ),
              Divider(color: Colors.grey[300], thickness: 1),
              const SizedBox(height: 20),
              // Action Button
              ElevatedButton.icon(
                onPressed: () => _showEditDialog(selectedTool!),
                icon: const Icon(Icons.edit, size: 20),
                label: const Text('Edit Tool Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors().primaryColor, // Button color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Reusable info row widget
//   Widget _buildInfoRow(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               title,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: Colors.black87,
//               ),
//               textAlign: TextAlign.right,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

  Widget _buildAddNewTool() {
    if (!_controller.canAddTools) {
      return const Center(child: Text('You do not have permission to add new tools'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '+ Add Tool',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildRoomDropdown(),
                const SizedBox(height: 16),
                _buildDateFields(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      decoration: InputDecoration(
        hintText: 'Tool Name',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) => 
        value?.isEmpty ?? true ? 'Please enter a tool name' : null,
      onSaved: (value) => _name = value!,
    );
  }

  Widget _buildRoomDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        hintText: 'Room',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      value: _selectedRoomId,
      items: _controller.locationRooms[_controller.userLocation?['name']]?.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList() ?? [],
      onChanged: (value) {
        setState(() {
          _selectedRoomId = value;
          _selectedLocation = _controller.userLocation?['name'];
        });
      },
      validator: (value) => 
        value == null ? 'Please select a room' : null,
    );
  }

  Widget _buildDateFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              hintText: 'Expiration Date',
              suffixIcon: const Icon(Icons.calendar_today),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            readOnly: true,
            onTap: () => _selectDate(context, false),
            controller: TextEditingController(
              text: _expirationDate != null
                ? DateFormat('dd MMM yyyy').format(_expirationDate!)
                : '',
            ),
            validator: (value) =>
              _expirationDate == null ? 'Please select a date' : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              hintText: 'Maintenance Date',
              suffixIcon: const Icon(Icons.calendar_today),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            readOnly: true,
            onTap: () => _selectDate(context, true),
            controller: TextEditingController(
              text: _maintenanceDate != null
                ? DateFormat('dd MMM yyyy').format(_maintenanceDate!)
                : '',
            ),
            validator: (value) =>
              _maintenanceDate == null ? 'Please select a date' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _submitNewTool,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors().primaryColor,
          minimumSize: const Size(200, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text('Add', style: TextStyle(color: Colors.white),),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
 @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}