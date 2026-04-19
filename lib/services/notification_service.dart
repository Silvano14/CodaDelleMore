import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service per la gestione delle notifiche
class NotificationService {
  static final _supabase = Supabase.instance.client;

  /// Recupera tutti gli ID utente dalla tabella profiles
  static Future<List<String>> _getAllUserIds() async {
    final response = await _supabase.from('profiles').select('id');
    return (response as List)
        .map((profile) => profile['id'] as String)
        .toList();
  }

  /// Invia notifica 'new_event' a tutti gli utenti
  static Future<void> sendNewEventNotifications(
    String eventId,
    String eventTitle,
  ) async {
    try {
      final userIds = await _getAllUserIds();
      final notifications = userIds
          .map((userId) => {
                'user_id': userId,
                'event_id': eventId,
                'title': 'Nuovo Evento',
                'message':
                    'Ti aspettiamo! Scopri "$eventTitle", il nostro nuovo evento.',
                'type': 'new_event',
                'scheduled_for': DateTime.now().toUtc().toIso8601String(),
              })
          .toList();

      await _supabase.from('notifications').insert(notifications);
    } catch (e) {
      debugPrint('Errore invio notifiche nuovo evento: $e');
    }
  }

  /// Invia notifica 'event_update' a tutti gli utenti
  static Future<void> sendUpdateNotifications(
    String eventId,
    String eventTitle,
  ) async {
    try {
      final userIds = await _getAllUserIds();
      final notifications = userIds
          .map((userId) => {
                'user_id': userId,
                'event_id': eventId,
                'title': 'Evento Aggiornato',
                'message':
                    'Ci sono novità per "$eventTitle"! Dai un\'occhiata ai dettagli.',
                'type': 'event_update',
                'scheduled_for': DateTime.now().toUtc().toIso8601String(),
              })
          .toList();

      await _supabase.from('notifications').insert(notifications);
    } catch (e) {
      debugPrint('Errore invio notifiche aggiornamento: $e');
    }
  }
}
