import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../pages/event_detail_page.dart';

/// Helper mixin per i colori gradiente delle card
mixin EventCardGradientColors {
  static const List<List<Color>> _gradientColors = [
    [Color(0xFF6B4CE6), Color(0xFF9B6EE8)],
    [Color(0xFFFF6B9D), Color(0xFFFFA06B)],
    [Color(0xFF00C9FF), Color(0xFF92FE9D)],
    [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    [Color(0xFF4776E6), Color(0xFF8E54E9)],
  ];

  Color getGradientColor(int index) {
    return _gradientColors[index % _gradientColors.length][0];
  }

  Color getGradientEndColor(int index) {
    return _gradientColors[index % _gradientColors.length][1];
  }
}

/// Card a larghezza piena per la lista eventi principale
class FullWidthEventCard extends StatelessWidget with EventCardGradientColors {
  final Map<String, dynamic> event;

  FullWidthEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime.parse(event['event_date']);
    final formattedDay = DateFormat('dd').format(eventDate);
    final formattedMonth = DateFormat(
      'MMM',
      'it_IT',
    ).format(eventDate).substring(0, 3);
    final startTime = event['start_event_time'].toString().substring(0, 5);
    final endTime = event['end_event_time'] != null
        ? event['end_event_time'].toString().substring(0, 5)
        : null;
    final eventTimeDisplay = endTime != null
        ? '$startTime - $endTime'
        : startTime;
    final cardIndex = event['id']?.hashCode ?? 0;
    final coverImage = event['cover_image'] as String?;
    final coverVideo = event['cover_video'] as String?;
    final maxParticipants = event['max_participants'] as int?;
    final hasVideo = coverVideo != null && coverVideo.isNotEmpty;

    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: coverImage == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      getGradientColor(cardIndex),
                      getGradientEndColor(cardIndex),
                    ],
                  )
                : null,
            image: coverImage != null
                ? DecorationImage(
                    image: NetworkImage(coverImage),
                    fit: BoxFit.cover,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Badge data
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        formattedDay,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2942),
                          height: 1,
                        ),
                      ),
                      Text(
                        formattedMonth,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2942),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Badge posti limitati e video
              Positioned(
                top: 12,
                left: 70,
                child: Row(
                  children: [
                    if (maxParticipants != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Max $maxParticipants',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (hasVideo)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              // Cuore
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 22,
                    color: Color(0xFF2C2942),
                  ),
                ),
              ),
              // Info evento
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event['title'] ?? 'Senza titolo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            eventTimeDisplay,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          if (event['location'] != null) ...[
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event['location'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card orizzontale per eventi popolari
class PopularEventCard extends StatelessWidget with EventCardGradientColors {
  final Map<String, dynamic> event;

  PopularEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime.parse(event['event_date']);
    final formattedDay = DateFormat('dd').format(eventDate);
    final formattedMonth = DateFormat(
      'MMM',
      'it_IT',
    ).format(eventDate).substring(0, 3);
    final startTime = event['start_event_time'].toString().substring(0, 5);
    final endTime = event['end_event_time'] != null
        ? event['end_event_time'].toString().substring(0, 5)
        : null;
    final eventTime = endTime != null ? '$startTime - $endTime' : startTime;
    final cardIndex = event['id']?.hashCode ?? 0;
    final coverImage = event['cover_image'] as String?;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: coverImage == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      getGradientColor(cardIndex),
                      getGradientEndColor(cardIndex),
                    ],
                  )
                : null,
            image: coverImage != null
                ? DecorationImage(
                    image: NetworkImage(coverImage),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Stack(
            children: [
              // Badge data
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        formattedDay,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2942),
                          height: 1,
                        ),
                      ),
                      Text(
                        formattedMonth,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2942),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Cuore
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 20,
                    color: Color(0xFF2C2942),
                  ),
                ),
              ),
              // Info evento
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event['title'] ?? 'Senza titolo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eventTime,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      if (event['location'] != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event['location'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card per visualizzazione a griglia
class GridEventCard extends StatelessWidget with EventCardGradientColors {
  final Map<String, dynamic> event;

  GridEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime.parse(event['event_date']);
    final formattedDay = DateFormat('dd').format(eventDate);
    final formattedMonth = DateFormat(
      'MMM',
      'it_IT',
    ).format(eventDate).substring(0, 3);
    final startTime = event['start_event_time'].toString().substring(0, 5);
    final endTime = event['end_event_time'] != null
        ? event['end_event_time'].toString().substring(0, 5)
        : null;
    final eventTime = endTime != null ? '$startTime - $endTime' : startTime;
    final cardIndex = event['id']?.hashCode ?? 0;
    final coverImage = event['cover_image'] as String?;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(event: event),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: coverImage == null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    getGradientColor(cardIndex),
                    getGradientEndColor(cardIndex),
                  ],
                )
              : null,
          image: coverImage != null
              ? DecorationImage(
                  image: NetworkImage(coverImage),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Badge data
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      formattedDay,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2942),
                        height: 1,
                      ),
                    ),
                    Text(
                      formattedMonth,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2942),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Cuore
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border,
                  size: 16,
                  color: Color(0xFF2C2942),
                ),
              ),
            ),
            // Info evento
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event['title'] ?? 'Senza titolo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      eventTime,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    if (event['location'] != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              event['location'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
