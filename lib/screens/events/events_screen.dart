
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../widgets/event_card.dart';
import 'event_editor_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  Future<void> _openEditor(BuildContext context, {Event? event}) async {
    final provider = context.read<EventProvider>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditorScreen(
          initialDate: event?.eventDateTime ?? provider.selectedDate,
          event: event,
        ),
      ),
    );
  }

  Future<void> _deleteEvent(BuildContext context, Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text(
          'Are you sure you want to delete "${event.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success =
          await context.read<EventProvider>().deleteEvent(event.id);

      if (!success && context.mounted) {
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

  Map<DateTime, List<Event>> _groupEventsByDate(List<Event> events) {
    final grouped = <DateTime, List<Event>>{};

    for (final event in events) {
      final date = DateTime(
        event.eventDateTime.year,
        event.eventDateTime.month,
        event.eventDateTime.day,
      );

      grouped.putIfAbsent(date, () => []).add(event);
    }

    // Sort events inside each date by time.
    for (final eventsOnDate in grouped.values) {
      eventsOnDate.sort(
        (a, b) => a.eventDateTime.compareTo(b.eventDateTime),
      );
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final events = provider.events;

    final groupedEvents = _groupEventsByDate(events);

    final sortedDates = groupedEvents.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Events',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      

      body: SafeArea(
        child: provider.isLoading && events.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : provider.error != null && events.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : events.isEmpty
                    ? _EmptyEvents(
                        onAdd: () => _openEditor(context),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          16,
                          20,
                          100,
                        ),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final date = sortedDates[index];
                          final dateEvents = groupedEvents[date]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // DATE HEADER
                              Padding(
                                padding: EdgeInsets.only(
                                  top: index == 0 ? 0 : 18,
                                  bottom: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            DateFormat('MMM')
                                                .format(date)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('d').format(date),
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('EEEE')
                                              .format(date),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight:
                                                    FontWeight.w800,
                                              ),
                                        ),
                                        Text(
                                          DateFormat('MMMM d, y')
                                              .format(date),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // EVENTS FOR THIS DATE
                              ...dateEvents.map(
                                (event) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 10,
                                  ),
                                  child: EventCard(
                                    event: event,
                                    onTap: () => _openEditor(
                                      context,
                                      event: event,
                                    ),
                                    onDelete: () => _deleteEvent(
                                      context,
                                      event,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyEvents({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No events yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first event and it will appear here organized by date.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}

