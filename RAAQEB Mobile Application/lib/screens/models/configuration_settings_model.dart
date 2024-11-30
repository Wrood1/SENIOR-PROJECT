class RoomConfiguration {
  Map<String, dynamic> priorities;
  Map<String, dynamic> thresholds;

  RoomConfiguration({
    required this.priorities,
    required this.thresholds,
  });

  factory RoomConfiguration.initial() {
    return RoomConfiguration(
      priorities: {
        'temperature': 2,
        'humidity': 2,
        'gas': 2,
      },
      thresholds: {
        'temperature': {'medium': 25.0, 'maximum': 35.0},
        'humidity': {'medium': 60.0, 'maximum': 80.0},
        'gas': {'medium': 30.0, 'maximum': 50.0},
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'priorities': priorities,
      'thresholds': thresholds,
    };
  }
}