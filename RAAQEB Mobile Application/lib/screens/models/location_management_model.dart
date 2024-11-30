
class Room {
  Map<String, List<String>> sensorsByType; 
  Map<String, String> sensorValues; 
  String id;
  String name;
  String? selectedSensorType;
  int level;

  Room({required this.id})
      : sensorsByType = {},
        sensorValues = {},
        selectedSensorType = null,
        name = '',
        level = 1;

  int getNextSensorNumber(String type) {
    if (!sensorsByType.containsKey(type)) {
      return 1;
    }
    List<String> sensors = sensorsByType[type] ?? [];
    if (sensors.isEmpty) return 1;
    
    List<int> numbers = sensors
        .map((s) => int.tryParse(s.replaceAll(type, '')) ?? 0)
        .toList();
    numbers.sort();
    return numbers.last + 1;
  }

  void addSensor(String type) {
    if (!sensorsByType.containsKey(type)) {
      sensorsByType[type] = [];
    }
    int nextNum = getNextSensorNumber(type);
    String sensorId = '$type$nextNum';
    sensorsByType[type]!.add(sensorId);
    
    switch (type) {
      case 'temp':
        sensorValues[sensorId] = '25';
        break;
      case 'humidity':
        sensorValues[sensorId] = '50';
        break;
      case 'gas':
        sensorValues[sensorId] = '0';
        break;
      case 'fire':
        sensorValues[sensorId] = '0';
        break;
      default:
        sensorValues[sensorId] = '0';
    }
  }

  void removeSensor(String sensorId) {
    String? type = sensorsByType.keys.firstWhere(
      (t) => sensorId.startsWith(t),
      orElse: () => '',
    );
    if (type.isNotEmpty) {
      sensorsByType[type]?.remove(sensorId);
      if (sensorsByType[type]?.isEmpty ?? false) {
        sensorsByType.remove(type);
      }
    }
    sensorValues.remove(sensorId);
  }
}