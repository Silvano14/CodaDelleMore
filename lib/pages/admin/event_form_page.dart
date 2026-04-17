import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/colors.dart';

class EventFormPage extends StatefulWidget {
  final Map<String, dynamic>? event;

  const EventFormPage({super.key, this.event});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

enum MediaType { none, image, video }

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

      if (widget.event != null) {
        await Supabase.instance.client
            .from('events')
            .update(eventData)
            .eq('id', widget.event!['id']);
      } else {
        await Supabase.instance.client.from('events').insert(eventData);
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
    final hasMedia =
        _selectedMedia != null ||
        (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) ||
        (_existingVideoUrl != null && _existingVideoUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media di copertina',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: hasMedia
              ? Stack(
                  children: [
                    // Preview del media
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _mediaType == MediaType.video
                          ? Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.black87,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.videocam,
                                    size: 64,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Video selezionato',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _selectedMedia != null
                          ? Image.file(
                              _selectedMedia!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Image.network(
                              _existingImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                    // Loading overlay
                    if (_isUploadingMedia)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    // Bottoni
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => _showMediaPickerDialog(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _removeMedia,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: () => _showMediaPickerDialog(),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.videocam_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tocca per aggiungere immagine o video',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lascia vuoto per usare un colore casuale',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  void _showMediaPickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleziona tipo di media',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, color: Color(0xFF2C2942)),
                ),
                title: const Text('Immagine'),
                subtitle: const Text('Seleziona dalla galleria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.videocam, color: Color(0xFF2C2942)),
                ),
                title: const Text('Video'),
                subtitle: const Text('Max 2 minuti'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
            ],
          ),
        ),
      ),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.book_online,
                        color: Colors.grey[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prenotazioni',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _bookingsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _bookingsEnabled = value;
                          });
                        },
                        activeTrackColor: AppColors.primary,
                      ),
                    ],
                  ),
                  Text(
                    _bookingsEnabled
                        ? 'Le prenotazioni sono aperte'
                        : 'Le prenotazioni sono chiuse',
                    style: TextStyle(
                      fontSize: 12,
                      color: _bookingsEnabled ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contatto telefono
                  TextFormField(
                    controller: _contactPhoneController,
                    decoration: InputDecoration(
                      labelText: 'Telefono per prenotazioni',
                      hintText: 'es. 346 1234567',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  // Prezzo e Scadenza in row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Prezzo',
                            hintText: 'es. 15',
                            prefixIcon: const Icon(Icons.euro),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*[,.]?\d{0,2}'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _selectBookingDeadline,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Scadenza',
                              prefixIcon: const Icon(Icons.event_busy),
                              suffixIcon: _bookingDeadline != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: _clearBookingDeadline,
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            child: Text(
                              _bookingDeadline != null
                                  ? DateFormat(
                                      'dd/MM',
                                    ).format(_bookingDeadline!)
                                  : 'Nessuna',
                              style: TextStyle(
                                color: _bookingDeadline != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
