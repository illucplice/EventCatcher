import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../services/firestore_service.dart';

class EventProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<Event> _events = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Event>>? _subscription;
  String? _uid;

  List<Event> get events => List.unmodifiable(_events);
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Event> get selectedDateEvents {
    return _events.where((event) => _sameDay(event.eventDateTime, _selectedDate)).toList();
  }

  bool hasEventOn(DateTime day) {
    return _events.any((event) => _sameDay(event.eventDateTime, day));
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void startListening(String uid) {
    if (_uid == uid && _subscription != null) return;

    _uid = uid;
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _service.watchEvents(uid).listen(
      (items) {
        _events = items;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _error = 'Unable to load events. Check your connection.';
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _events = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createEvent(Event event) async {
    if (_uid == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.createEvent(_uid!, event);
      return true;
    } on FirebaseException catch (_) {
      _error = 'Could not create the event.';
      return false;
    } catch (_) {
      _error = 'Could not create the event.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEvent(Event event) async {
    if (_uid == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateEvent(_uid!, event);
      return true;
    } on FirebaseException catch (_) {
      _error = 'Could not update the event.';
      return false;
    } catch (_) {
      _error = 'Could not update the event.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    if (_uid == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteEvent(_uid!, eventId);
      return true;
    } on FirebaseException catch (_) {
      _error = 'Could not delete the event.';
      return false;
    } catch (_) {
      _error = 'Could not delete the event.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}