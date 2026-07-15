class Task {
  final String id;
  final String title;
  final DateTime dateTime;
  bool isCompleted;
  final bool isSilent;

  Task({
    required this.id,
    required this.title,
    required this.dateTime,
    this.isCompleted = false,
    this.isSilent = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'isCompleted': isCompleted,
      'isSilent': isSilent,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      dateTime: DateTime.parse(json['dateTime']),
      isCompleted: json['isCompleted'] ?? false,
      isSilent: json['isSilent'] ?? false,
    );
  }
}
