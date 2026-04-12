import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';
import '../models/profile.dart';
import 'admin/admin_events_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

enum TimeFilter { all, today, thisWeek, thisMonth, custom }

class _EventsPageState extends State<EventsPage> {
  TimeFilter _selectedFilter = TimeFilter.all;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('events')
          .select()
          .order('event_date', ascending: true)
          .order('event_time', ascending: true);

      setState(() {
        _events = (response as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshEvents() async {
    final response = await Supabase.instance.client
        .from('events')
        .select()
        .order('event_date', ascending: true)
        .order('event_time', ascending: true);

    setState(() {
      _events = (response as List).cast<Map<String, dynamic>>();
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<Profile?> _loadProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return Profile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> _filterEventsByTime(List<dynamic> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return events
        .where((event) {
          final eventDate = DateTime.parse(event['event_date']);
          final eventDay = DateTime(
            eventDate.year,
            eventDate.month,
            eventDate.day,
          );

          switch (_selectedFilter) {
            case TimeFilter.all:
              return eventDate.isAfter(now.subtract(const Duration(days: 1)));
            case TimeFilter.today:
              return eventDay.isAtSameMomentAs(today);
            case TimeFilter.thisWeek:
              final weekStart = today.subtract(
                Duration(days: today.weekday - 1),
              );
              final weekEnd = weekStart.add(const Duration(days: 6));
              return eventDay.isAfter(
                    weekStart.subtract(const Duration(days: 1)),
                  ) &&
                  eventDay.isBefore(weekEnd.add(const Duration(days: 1)));
            case TimeFilter.thisMonth:
              return eventDate.year == now.year && eventDate.month == now.month;
            case TimeFilter.custom:
              if (_customStartDate != null && _customEndDate != null) {
                return eventDay.isAfter(
                      _customStartDate!.subtract(const Duration(days: 1)),
                    ) &&
                    eventDay.isBefore(
                      _customEndDate!.add(const Duration(days: 1)),
                    );
              }
              return true;
          }
        })
        .toList()
        .cast<Map<String, dynamic>>();
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Errore: $_error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEvents,
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredEvents = _filterEventsByTime(_events);

    if (filteredEvents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshEvents,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nessun evento disponibile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Non ci sono eventi per il periodo selezionato',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          return FullWidthEventCard(event: filteredEvents[index]);
        },
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
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
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedFilter = TimeFilter.custom;
      });
    }
  }

  Widget _buildFilterChip(String label, TimeFilter filter) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      selectedColor: const Color(0xFF2C2942),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF2C2942),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildCustomFilterChip() {
    final isSelected = _selectedFilter == TimeFilter.custom;
    String label = 'Personalizzato';
    if (isSelected && _customStartDate != null && _customEndDate != null) {
      label =
          '${DateFormat('dd/MM').format(_customStartDate!)} - ${DateFormat('dd/MM').format(_customEndDate!)}';
    }

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          const Icon(Icons.calendar_today, size: 14),
        ],
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        _showCustomDatePicker();
      },
      selectedColor: const Color(0xFF2C2942),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF2C2942),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? badge,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? const Color(0xFF2C2942) : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? const Color(0xFF2C2942) : Colors.grey.shade900,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2942),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      selected: selected,
      selectedTileColor: const Color(0xFF2C2942).withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, authSnapshot) {
          final session = authSnapshot.hasData
              ? authSnapshot.data!.session
              : null;
          final isLoggedIn = session != null;

          return FutureBuilder<Profile?>(
            future: isLoggedIn
                ? _loadProfile(session.user.id)
                : Future.value(null),
            builder: (context, profileSnapshot) {
              final profile = profileSnapshot.data;
              final isAdmin = profile?.isAdmin ?? false;

              return Drawer(
                child: Column(
                  children: [
                    // Header con gradiente
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2C2942), Color(0xFF4776E6)],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo/Icona app
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.event_available,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Coda delle More',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isLoggedIn) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          session.user.email ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else
                                Text(
                                  'Benvenuto!',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Menu items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          _buildDrawerItem(
                            icon: Icons.event,
                            title: 'Eventi',
                            selected: true,
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                          if (isLoggedIn) ...[
                            _buildDrawerItem(
                              icon: Icons.favorite,
                              title: 'Preferiti',
                              onTap: () {
                                Navigator.pop(context);
                                // TODO: Navigare alla pagina preferiti
                              },
                            ),
                            _buildDrawerItem(
                              icon: Icons.notifications,
                              title: 'Notifiche',
                              badge: '3', // TODO: Numero notifiche non lette
                              onTap: () {
                                Navigator.pop(context);
                                // TODO: Navigare alla pagina notifiche
                              },
                            ),
                          ],
                          if (isAdmin) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Divider(),
                            ),
                            _buildDrawerItem(
                              icon: Icons.admin_panel_settings,
                              title: 'Gestione Eventi',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminEventsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Divider(),
                          ),
                          if (isLoggedIn)
                            _buildDrawerItem(
                              icon: Icons.settings,
                              title: 'Impostazioni',
                              onTap: () {
                                Navigator.pop(context);
                                // TODO: Navigare alle impostazioni
                              },
                            ),
                          _buildDrawerItem(
                            icon: Icons.info_outline,
                            title: 'Info',
                            onTap: () {
                              Navigator.pop(context);
                              // TODO: Mostrare dialog info
                            },
                          ),
                        ],
                      ),
                    ),
                    // Footer con login/logout
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: isLoggedIn
                              ? ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _signOut();
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Logout'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    foregroundColor: Colors.red,
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.login),
                                  label: const Text('Login'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2C2942),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      body: Column(
        children: [
          // Header fisso
          ClipPath(
            clipper: HeaderClipper(),
            child: Container(
              color: const Color(0xFF2C2942),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(
                                Icons.menu,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Eventi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filtri temporali fissi
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tutti', TimeFilter.all),
                  const SizedBox(width: 8),
                  _buildFilterChip('Oggi', TimeFilter.today),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Questa settimana',
                    TimeFilter.thisWeek,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip('Questo mese', TimeFilter.thisMonth),
                  const SizedBox(width: 8),
                  _buildCustomFilterChip(),
                ],
              ),
            ),
          ),

          // Contenuto scrollabile con pull-to-refresh
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}

class FullWidthEventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const FullWidthEventCard({super.key, required this.event});

  Color _getGradientColor(int index) {
    final colors = [
      [const Color(0xFF6B4CE6), const Color(0xFF9B6EE8)],
      [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)],
      [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
      [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
    ];
    return colors[index % colors.length][0];
  }

  Color _getGradientEndColor(int index) {
    final colors = [
      [const Color(0xFF6B4CE6), const Color(0xFF9B6EE8)],
      [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)],
      [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
      [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
    ];
    return colors[index % colors.length][1];
  }

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime.parse(event['event_date']);
    final formattedDay = DateFormat('dd').format(eventDate);
    final formattedMonth = DateFormat(
      'MMM',
      'it_IT',
    ).format(eventDate).substring(0, 3);
    final eventTime = event['event_time'].toString().substring(0, 5);
    final cardIndex = event['id']?.hashCode ?? 0;
    final coverImage = event['cover_image'] as String?;

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
                      _getGradientColor(cardIndex),
                      _getGradientEndColor(cardIndex),
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
                            eventTime,
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

class PopularEventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const PopularEventCard({super.key, required this.event});

  Color _getGradientColor(int index) {
    final colors = [
      [const Color(0xFF6B4CE6), const Color(0xFF9B6EE8)],
      [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)],
      [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
      [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
    ];
    return colors[index % colors.length][0];
  }

  Color _getGradientEndColor(int index) {
    final colors = [
      [const Color(0xFF6B4CE6), const Color(0xFF9B6EE8)],
      [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)],
      [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
      [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
    ];
    return colors[index % colors.length][1];
  }

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime.parse(event['event_date']);
    final formattedDay = DateFormat('dd').format(eventDate);
    final formattedMonth = DateFormat(
      'MMM',
      'it_IT',
    ).format(eventDate).substring(0, 3);
    final eventTime = event['event_time'].toString().substring(0, 5);
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
                      _getGradientColor(cardIndex),
                      _getGradientEndColor(cardIndex),
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

class GridEventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const GridEventCard({super.key, required this.event});

  Color _getGradientColor(int index) {
    final colors = [
      [const Color(0xFF6B4CE6), const Color(0xFF9B6EE8)],
      [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)],
      [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
      [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
    ];
    return colors[index % colors.length][0];
  }

  Color _getGradientEndColor(int index) {
    final colors = [
      [const Color(0xFF6B4CE6), const Color(0xFF9B6EE8)],
      [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)],
      [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
      [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
    ];
    return colors[index % colors.length][1];
  }

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime.parse(event['event_date']);
    final formattedDay = DateFormat('dd').format(eventDate);
    final formattedMonth = DateFormat(
      'MMM',
      'it_IT',
    ).format(eventDate).substring(0, 3);
    final eventTime = event['event_time'].toString().substring(0, 5);
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
                    _getGradientColor(cardIndex),
                    _getGradientEndColor(cardIndex),
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

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);

    // Curva più morbida e naturale
    path.quadraticBezierTo(
      size.width / 2, // punto di controllo x (centro)
      size.height + 10, // punto di controllo y (fondo più pronunciato)
      size.width, // punto finale x
      size.height - 40, // punto finale y
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class EventDetailPage extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailPage({super.key, required this.event});

  Color _getGradientColor(int index) {
    final colors = [
      [const Color(0xFF6B4CE6), const Color(0xFF9B6EE8)],
      [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)],
      [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
      [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
    ];
    return colors[index % colors.length][0];
  }

  Color _getGradientEndColor(int index) {
    final colors = [
      [const Color(0xFF6B4CE6), const Color(0xFF9B6EE8)],
      [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)],
      [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
      [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
      [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
    ];
    return colors[index % colors.length][1];
  }

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime.parse(event['event_date']);
    final formattedDate = DateFormat('dd MMMM yyyy', 'it_IT').format(eventDate);
    final formattedDay = DateFormat('dd').format(eventDate);
    final formattedMonth = DateFormat('MMM', 'it_IT').format(eventDate);
    final eventTime = event['event_time'].toString().substring(0, 5);
    final cardIndex = event['id']?.hashCode ?? 0;
    final coverImage = event['cover_image'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: coverImage == null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getGradientColor(cardIndex),
                            _getGradientEndColor(cardIndex),
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
                    // Overlay scuro per leggibilità del titolo
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'] ?? 'Senza titolo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 70,
                              decoration: BoxDecoration(
                                color: _getGradientColor(cardIndex),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    formattedDay,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    formattedMonth.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        eventTime,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (event['location'] != null) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getGradientColor(
                                    cardIndex,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: _getGradientColor(cardIndex),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Luogo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      event['location'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Info',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event['description'] ?? 'Nessuna descrizione disponibile',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
