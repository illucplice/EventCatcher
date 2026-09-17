import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event.dart';

class CalendarSection extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final List<Event> events;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  const CalendarSection({
    super.key,
    required this.selectedDay,
    required this.focusedDay,
    required this.events,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  bool _hasEvent(DateTime day) {
    return events.any((event) =>
        event.eventDateTime.year == day.year &&
        event.eventDateTime.month == day.month &&
        event.eventDateTime.day == day.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: TableCalendar<Event>(
          firstDay: DateTime(2020),
          lastDay: DateTime(2035),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) =>
              day.year == selectedDay.year &&
              day.month == selectedDay.month &&
              day.day == selectedDay.day,
          eventLoader: (day) => _hasEvent(day) ? [events.first] : [],
          onDaySelected: (selected, focused) {
            onDaySelected(selected);
          },
          onPageChanged: onPageChanged,
          calendarFormat: CalendarFormat.month,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            markerDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}