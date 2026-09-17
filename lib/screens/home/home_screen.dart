import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/calendar_section.dart';
import '../../widgets/event_card.dart';
import '../events/event_editor_screen.dart';
import '../events/events_screen.dart';
import '../settings/settings_screen.dart';
import '../../models/event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();

  // 0 = Home
  // 1 = Events
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    final user = context.read<AuthProvider>().user;

    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<EventProvider>().startListening(user.uid);
        }
      });
    }
  }

  Future<void> _openEditor({Event? event}) async {
    final provider = context.read<EventProvider>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditorScreen(
          initialDate: provider.selectedDate,
          event: event,
        ),
      ),
    );
  }

  Future<void> _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text(
          'Are you sure you want to delete "${event.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<EventProvider>().deleteEvent(event.id);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<EventProvider>().error ?? 'Delete failed.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<EventProvider>();

    final userName = auth.user?.displayName?.trim();

    final greetingName =
        (userName == null || userName.isEmpty) ? 'there' : userName;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(
            context,
            provider,
            greetingName,
          ),
          const EventsScreen(),
        ],
      ),

      // =========================
      // BOTTOM NAVIGATION BAR
      // =========================
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
          ),
        ],
      ),
    );
  }

  // =========================
  // HOME PAGE
  // =========================

  Widget _buildHomePage(
    BuildContext context,
    EventProvider provider,
    String greetingName,
  ) {
    final selectedEvents = provider.selectedDateEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EventCatcher',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            ),
            icon: const Icon(
              Icons.settings_outlined,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Event',
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(
              const Duration(
                milliseconds: 300,
              ),
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              110,
            ),
            children: [
              // =========================
              // GREETING
              // =========================

              Text(
                'Good ${DateTime.now().hour < 12 ? 'Morning' : DateTime.now().hour < 18 ? 'Afternoon' : 'Evening'}, $greetingName 👋',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),

              const SizedBox(height: 6),

              Text(
                DateFormat.yMMMM().format(
                  provider.selectedDate,
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: 16),

              // =========================
              // CALENDAR
              // =========================

              CalendarSection(
                selectedDay: provider.selectedDate,
                focusedDay: _focusedDay,
                events: provider.events,
                onDaySelected: (date) {
                  provider.setSelectedDate(date);

                  setState(() {
                    _focusedDay = date;
                  });
                },
                onPageChanged: (date) {
                  setState(() {
                    _focusedDay = date;
                  });
                },
              ),

              const SizedBox(height: 24),

              // =========================
              // SELECTED DATE TITLE
              // =========================

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Events for ${DateFormat.yMMMMd().format(provider.selectedDate)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (selectedEvents.isNotEmpty)
                    Text(
                      '${selectedEvents.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // =========================
              // LOADING
              // =========================

              if (provider.isLoading && provider.events.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )

              // =========================
              // ERROR
              // =========================

              else if (provider.error != null && provider.events.isEmpty)
                _ErrorState(
                  message: provider.error!,
                )

              // =========================
              // NO EVENTS
              // =========================

              else if (selectedEvents.isEmpty)
                _EmptyState(
                  onAdd: () => _openEditor(),
                )

              // =========================
              // EVENTS
              // =========================

              else
                ...selectedEvents.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: EventCard(
                      event: event,
                      onTap: () => _openEditor(
                        event: event,
                      ),
                      onDelete: () => _deleteEvent(
                        event,
                      ),
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

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 46,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No events scheduled',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create an event for this date.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Create Event',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR STATE
// ============================================================

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
