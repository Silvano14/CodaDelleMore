/// Modello per la relazione utente-evento (preferiti/partecipazioni)
class UserEvent {
  final String id;
  final String userId;
  final String eventId;
  final bool isFavorite;
  final bool isParticipating;
  final DateTime createdAt;

  UserEvent({
    required this.id,
    required this.userId,
    required this.eventId,
    this.isFavorite = false,
    this.isParticipating = false,
    required this.createdAt,
  });

  factory UserEvent.fromJson(Map<String, dynamic> json) {
    return UserEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      isFavorite: json['is_favorite'] as bool? ?? false,
      isParticipating: json['is_participating'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'is_favorite': isFavorite,
      'is_participating': isParticipating,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserEvent copyWith({
    String? id,
    String? userId,
    String? eventId,
    bool? isFavorite,
    bool? isParticipating,
    DateTime? createdAt,
  }) {
    return UserEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      isFavorite: isFavorite ?? this.isFavorite,
      isParticipating: isParticipating ?? this.isParticipating,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
