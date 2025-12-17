class NotificationModel {
  final int id;
  final String verb;
  final String timestamp;
  final bool deleted;
  final String? description;
  final Map<String, dynamic>? actor;
  final Map<String, dynamic>? target;
  final Map<String, dynamic>? actionObject;

  NotificationModel({
    required this.id,
    required this.verb,
    required this.timestamp,
    required this.deleted,
    this.description,
    this.actor,
    this.target,
    this.actionObject,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      verb: json['verb'] ?? '',
      timestamp: json['timestamp'] ?? '',
      deleted: json['deleted'] ?? false,
      description: json['description'],
      actor: json['actor'],
      target: json['target'],
      actionObject: json['action_object'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'verb': verb,
      'timestamp': timestamp,
      'deleted': deleted,
      'description': description,
      'actor': actor,
      'target': target,
      'action_object': actionObject,
    };
  }
}

class NotificationResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<NotificationModel> results;

  NotificationResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>?)
          ?.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}