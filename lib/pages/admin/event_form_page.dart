import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/colors.dart';
import '../../services/notification_service.dart';
import '../../widgets/event_form/media_picker_widget.dart';
import '../../widgets/event_form/bookings_section_widget.dart';

class EventFormPage extends StatefulWidget {
  final Map<String, dynamic>? event;

  const EventFormPage({super.key, this.event});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _priceController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _bookingDeadline;
  String? _selectedCategory;
  bool _isPublished = true;
  bool _bookingsEnabled = true;
  bool _isLoading = false;

  // Media (immagine o video)
  File? _selectedMedia;
  String? _existingImageUrl;
  String? _existingVideoUrl;
  MediaType _mediaType = MediaType.none;
  bool _isUploadingMedia = false;

  final List<String> _categories = [
    'Musica',
    'Sport',
    'Cultura',
    'Cibo',
    'Tecnologia',
    'Arte',
    'Festival',
    'Altro',
  ];

  static const String _defaultLocation = 'Via Udine, 31, 33080 Zoppola PN';

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _loadEventData();
    } else {
      _locationController.text = _defaultLocation;
    }
  }

  void _loadEventData() {
    final event = widget.event!;
    _titleController.text = event['title'] ?? '';
    _descriptionController.text = event['description'] ?? '';
    _locationController.text = event['location'] ?? _defaultLocation;
    _existingImageUrl = event['cover_image'];
    _existingVideoUrl = event['cover_video'];
    _maxParticipantsController.text =
        event['max_participants']?.toString() ?? '';
    _contactPhoneController.text = event['contact_phone'] ?? '';
    _priceController.text = event['price']?.toString() ?? '';
    _selectedCategory = event['category'];
    _isPublished = event['is_published'] as bool? ?? true;
    _bookingsEnabled = event['bookings_enabled'] as bool? ?? true;

    _selectedDate = DateTime.parse(event['event_date']);

    final timeParts = event['start_event_time'].toString().split(':');
    _startTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    if (event['booking_deadline'] != null) {
      _bookingDeadline = DateTime.parse(event['booking_deadline']);
    }

    // Carica ora fine se presente
    if (event['end_event_time'] != null) {
      final endTimeParts = event['end_event_time'].toString().split(':');
      _endTime = TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      );
    }

    // Determina il tipo di media esistente
    if (_existingVideoUrl != null && _existingVideoUrl!.isNotEmpty) {
      _mediaType = MediaType.video;
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      _mediaType = MediaType.image;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _contactPhoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2C2942)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2C2942)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2C2942)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _clearEndTime() {
    setState(() {
      _endTime = null;
    });
  }

  Future<void> _selectBookingDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _bookingDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: _selectedDate ?? DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2C2942)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _bookingDeadline = picked;
      });
    }
  }

  void _clearBookingDeadline() {
    setState(() {
      _bookingDeadline = null;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedMedia = File(image.path);
        _mediaType = MediaType.image;
        _existingVideoUrl = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();

    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );

    if (video != null) {
      setState(() {
        _selectedMedia = File(video.path);
        _mediaType = MediaType.video;
        _existingImageUrl = null;
      });
    }
  }

  Future<Map<String, String?>> _uploadMedia() async {
    String? imageUrl = _existingImageUrl;
    String? videoUrl = _existingVideoUrl;

    if (_selectedMedia == null) {
      return {'image': imageUrl, 'video': videoUrl};
    }

    setState(() {
      _isUploadingMedia = true;
    });

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedMedia!.path.split('/').last}';
      final bytes = await _selectedMedia!.readAsBytes();

      final bucketName = _mediaType == MediaType.video
          ? 'event-videos'
          : 'event-images';

      await Supabase.instance.client.storage
          .from(bucketName)
          .uploadBinary(fileName, bytes);

      final url = Supabase.instance.client.storage
          .from(bucketName)
          .getPublicUrl(fileName);

      if (_mediaType == MediaType.video) {
        videoUrl = url;
        imageUrl = null;
      } else {
        imageUrl = url;
        videoUrl = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore upload media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }
    }

    return {'image': imageUrl, 'video': videoUrl};
  }

  void _removeMedia() {
    setState(() {
      _selectedMedia = null;
      _existingImageUrl = null;
      _existingVideoUrl = null;
      _mediaType = MediaType.none;
    });
  }

  /// Dialog per chiedere se notificare gli utenti della modifica
  Future<bool?> _showNotifyUsersDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificare gli utenti?'),
        content: const Text(
          'Vuoi inviare una notifica a tutti gli utenti per informarli della modifica?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Notifica'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona data e ora dell\'evento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final startTimeString =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
      final endTimeString = _endTime != null
          ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00'
          : null;

      // Upload media se selezionato
      final mediaUrls = await _uploadMedia();

      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'event_date': _selectedDate!.toIso8601String().split('T')[0],
        'start_event_time': startTimeString,
        'end_event_time': endTimeString,
        'cover_image': mediaUrls['image'],
        'cover_video': mediaUrls['video'],
        'category': _selectedCategory,
        'is_published': _isPublished,
        'max_participants': _maxParticipantsController.text.isEmpty
            ? null
            : int.tryParse(_maxParticipantsController.text),
        'contact_phone': _contactPhoneController.text.trim().isEmpty
            ? null
            : _contactPhoneController.text.trim(),
        'price': _priceController.text.isEmpty
            ? null
            : double.tryParse(_priceController.text.replaceAll(',', '.')),
        'booking_deadline': _bookingDeadline?.toIso8601String().split('T')[0],
        'bookings_enabled': _bookingsEnabled,
        'created_by': userId,
      };

      final eventTitle = _titleController.text.trim();

      if (widget.event != null) {
        // UPDATE
        await Supabase.instance.client
            .from('events')
            .update(eventData)
            .eq('id', widget.event!['id']);

        // Chiedi se notificare gli utenti
        if (mounted) {
          final shouldNotify = await _showNotifyUsersDialog();
          if (shouldNotify == true) {
            await NotificationService.sendUpdateNotifications(widget.event!['id'], eventTitle);
          }
        }
      } else {
        // CREATE - ottieni l'ID del nuovo evento
        final response = await Supabase.instance.client
            .from('events')
            .insert(eventData)
            .select('id')
            .single();

        final newEventId = response['id'] as String;

        // Notifica automatica a tutti gli utenti
        await NotificationService.sendNewEventNotifications(newEventId, eventTitle);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event != null
                  ? 'Evento aggiornato con successo'
                  : 'Evento creato con successo',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMediaPicker() {
    return MediaPickerWidget(
      selectedMedia: _selectedMedia,
      existingImageUrl: _existingImageUrl,
      existingVideoUrl: _existingVideoUrl,
      mediaType: _mediaType,
      isUploading: _isUploadingMedia,
      onPickImage: _pickImage,
      onPickVideo: _pickVideo,
      onRemove: _removeMedia,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event != null ? 'Modifica Evento' : 'Nuovo Evento'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titolo
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Titolo *',
                hintText: 'Inserisci il titolo dell\'evento',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Inserisci un titolo';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descrizione
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descrizione',
                hintText: 'Descrivi l\'evento',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Data e Ora inizio in row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Data *',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : 'Seleziona',
                        style: TextStyle(
                          color: _selectedDate != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ora fine (opzionale)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Ora inizio *',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _startTime != null
                            ? _startTime!.format(context)
                            : 'Seleziona',
                        style: TextStyle(
                          color: _startTime != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: InkWell(
                    onTap: _selectEndTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Ora fine (opzionale)',
                        prefixIcon: const Icon(Icons.access_time_filled),
                        suffixIcon: _endTime != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: _clearEndTime,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _endTime != null
                            ? _endTime!.format(context)
                            : 'Non specificata',
                        style: TextStyle(
                          color: _endTime != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Luogo
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Luogo',
                hintText: 'Dove si svolge l\'evento',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Categoria
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoria',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              hint: const Text('Seleziona una categoria'),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Media Picker
            _buildMediaPicker(),
            const SizedBox(height: 24),

            // Sezione Prenotazioni
            BookingsSectionWidget(
              bookingsEnabled: _bookingsEnabled,
              onBookingsEnabledChanged: (value) {
                setState(() {
                  _bookingsEnabled = value;
                });
              },
              contactPhoneController: _contactPhoneController,
              priceController: _priceController,
              bookingDeadline: _bookingDeadline,
              onSelectDeadline: _selectBookingDeadline,
              onClearDeadline: _clearBookingDeadline,
            ),
            const SizedBox(height: 16),

            // Numero massimo partecipanti
            TextFormField(
              controller: _maxParticipantsController,
              decoration: InputDecoration(
                labelText: 'Partecipanti massimi',
                hintText: 'Numero massimo (opzionale)',
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText:
                    'Se non inserito, il limite non verrà mostrato nell\'evento',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Pubblicato
            SwitchListTile(
              value: _isPublished,
              onChanged: (value) {
                setState(() {
                  _isPublished = value;
                });
              },
              title: const Text('Pubblica evento'),
              subtitle: Text(
                _isPublished
                    ? 'L\'evento sarà visibile a tutti'
                    : 'L\'evento sarà salvato come bozza',
              ),
              secondary: Icon(
                _isPublished ? Icons.visibility : Icons.visibility_off,
                color: _isPublished ? Colors.green : Colors.grey,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 24),

            // Pulsante Salva
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.event != null ? 'Aggiorna Evento' : 'Crea Evento',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
