# DA DALT

Da dalt è una applicazione che si occupa di propagare il nome dell'azienda (coda delle more) e condividere eventi e occasioni di ritrovo che capitano più volte durante l'anno.

## Gestione codice sorgente

I file non devono avere un numero di righe che supera il 600, non è un limite assoluto ma se lo si supera bisogna pensare se il componente lo si può dividere in più file. Serve per poter facilitare la lettura e la gestione dei file, inoltre aiuta la IA a non dover leggere file troppo grandi consumando troppi token.

## Database

Quando generi query a database non dimenticare di assegnare la regole RLS corrette, non è ammessibile che ci siano tabelle accessibili da chiunque.
L'applicazione ha una visualizzazione admin e una visualizzazione utente.

Lo schema completo del database si trova in [DATABASE_SCHEMA.sql](DATABASE_SCHEMA.sql).

## Sistema di Notifiche

### Panoramica
L'applicazione implementa un sistema di notifiche per mantenere gli utenti informati sugli eventi a cui sono interessati.

### Tipi di Notifiche

1. **event_reminder** - Promemoria eventi
   - Inviata automaticamente 24 ore prima dell'evento per gli utenti che partecipano
   - Inviata automaticamente 1 ora prima dell'evento

2. **event_update** - Aggiornamento evento
   - Inviata quando un admin modifica un evento (data, ora, location)
   - Solo agli utenti che hanno l'evento nei favoriti o partecipano

3. **event_cancelled** - Evento cancellato
   - Inviata quando un admin elimina/annulla un evento
   - Solo agli utenti che hanno l'evento nei favoriti o partecipano

4. **new_event** - Nuovo evento
   - Inviata quando viene pubblicato un nuovo evento in una categoria seguita dall'utente
   - Opzionale, configurabile nelle impostazioni utente

5. **system** - Notifiche di sistema
   - Comunicazioni generali dall'amministrazione

### Implementazione nel Database

Le notifiche vengono create tramite trigger o manualmente dagli admin. Esempi:

```sql
-- Trigger per notifiche di aggiornamento evento
CREATE OR REPLACE FUNCTION notify_event_update()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.notifications (user_id, event_id, title, message, type, scheduled_for)
  SELECT
    ue.user_id,
    NEW.id,
    'Evento Modificato',
    'L''evento "' || NEW.title || '" è stato modificato.',
    'event_update',
    NOW()
  FROM public.user_events ue
  WHERE ue.event_id = NEW.id
    AND (ue.is_favorite = true OR ue.is_participating = true);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_event_update
  AFTER UPDATE ON public.events
  FOR EACH ROW
  WHEN (OLD.* IS DISTINCT FROM NEW.*)
  EXECUTE FUNCTION notify_event_update();
```

### Visualizzazione nell'App

Le notifiche vengono mostrate in:
- **Badge sul drawer**: Numero di notifiche non lette
- **Pagina notifiche**: Lista completa
- **Notifiche push**: (futura implementazione con FCM)

### Programmazione Notifiche

Le notifiche di promemoria vengono create automaticamente quando un utente si iscrive a un evento:

```dart
// Crea promemoria 24h prima
await supabase.from('notifications').insert({
  'user_id': userId,
  'event_id': eventId,
  'title': 'Promemoria Evento',
  'message': 'L\'evento inizierà domani!',
  'type': 'event_reminder',
  'scheduled_for': eventDateTime.subtract(Duration(hours: 24)),
});
```

### Invio Notifiche

**Fase 1 (Corrente)**: Polling in-app
- L'app controlla periodicamente le notifiche programmate
- Mostra badge e lista notifiche

**Fase 2 (Futura)**: Push Notifications con FCM
- Edge Function su Supabase (cron job)
- Invia notifiche push tramite Firebase Cloud Messaging
- Aggiorna campo `sent_at` dopo l'invio

### Best Practices

1. **Non sovraccaricare**: Massimo 1-2 notifiche al giorno per utente
2. **Raggruppa**: "3 eventi domani" invece di 3 notifiche separate
3. **Orari smart**: Evita notifiche notturne (23:00 - 07:00)
4. **Messaggi chiari**: Brevi con call-to-action specifica
5. **Dismissible**: L'utente può sempre ignorare/chiudere

---

## Architettura App

### Struttura Directory

```
lib/
├── main.dart
├── models/
│   ├── event.dart
│   ├── notification.dart
│   ├── profile.dart
│   └── user_event.dart
├── pages/
│   ├── events_page.dart
│   ├── event_detail_page.dart
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── admin/
│   │   ├── admin_dashboard.dart
│   │   ├── event_form_page.dart
│   │   └── users_management_page.dart
│   └── notifications/
│       └── notifications_page.dart
├── services/
│   ├── auth_service.dart
│   ├── event_service.dart
│   └── notification_service.dart
└── widgets/
    ├── event_card.dart
    ├── notification_badge.dart
    └── custom_drawer.dart
```

### Ruoli Utente

- **user**: Può visualizzare eventi, metterli nei preferiti, partecipare
- **admin**: CRUD completo su eventi, gestione utenti, invio notifiche manuali

---

## Convenzioni Codice

- **Nomi file**: snake_case
- **Nomi classi**: PascalCase
- **Costanti**: UPPER_CASE
- **Colori**: Centralizzati in `lib/constants/colors.dart`
- **Lingua**: Italiano per UI, inglese per codice
