class Event {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime eventDate;
  final String startEventTime;
  final String? endEventTime; // Ora fine evento (opzionale)
  final String? coverImage;
  final String? coverVideo;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;
  final int? maxParticipants;
  final String? category;
  final String? contactPhone;
  final double? price;
  final DateTime? bookingDeadline;

  Event({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.eventDate,
    required this.startEventTime,
    this.endEventTime,
    this.coverImage,
    this.coverVideo,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isPublished = true,
    this.maxParticipants,
    this.category,
    this.contactPhone,
    this.price,
    this.bookingDeadline,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String),
      startEventTime: json['start_event_time'] as String,
      endEventTime: json['end_event_time'] as String?,
      coverImage: json['cover_image'] as String?,
      coverVideo: json['cover_video'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isPublished: json['is_published'] as bool? ?? true,
      maxParticipants: json['max_participants'] as int?,
      category: json['category'] as String?,
      contactPhone: json['contact_phone'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      bookingDeadline: json['booking_deadline'] != null
          ? DateTime.parse(json['booking_deadline'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'start_event_time': startEventTime,
      'end_event_time': endEventTime,
      'cover_image': coverImage,
      'cover_video': coverVideo,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_published': isPublished,
      'max_participants': maxParticipants,
      'category': category,
      'contact_phone': contactPhone,
      'price': price,
      'booking_deadline': bookingDeadline?.toIso8601String().split('T')[0],
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'start_event_time': startEventTime,
      'end_event_time': endEventTime,
      'cover_image': coverImage,
      'cover_video': coverVideo,
      'created_by': createdBy,
      'is_published': isPublished,
      'max_participants': maxParticipants,
      'category': category,
      'contact_phone': contactPhone,
      'price': price,
      'booking_deadline': bookingDeadline?.toIso8601String().split('T')[0],
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? eventDate,
    String? startEventTime,
    String? endEventTime,
    String? coverImage,
    String? coverVideo,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
    int? maxParticipants,
    String? category,
    String? contactPhone,
    double? price,
    DateTime? bookingDeadline,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      startEventTime: startEventTime ?? this.startEventTime,
      endEventTime: endEventTime ?? this.endEventTime,
      coverImage: coverImage ?? this.coverImage,
      coverVideo: coverVideo ?? this.coverVideo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      category: category ?? this.category,
      contactPhone: contactPhone ?? this.contactPhone,
      price: price ?? this.price,
      bookingDeadline: bookingDeadline ?? this.bookingDeadline,
    );
  }

  DateTime get eventDateTime {
    final timeParts = startEventTime.split(':');
    return DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  bool get isPast {
    return eventDateTime.isBefore(DateTime.now());
  }

  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    return eventDay.isAtSameMomentAs(today);
  }
}
