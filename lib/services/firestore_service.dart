import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _events(String uid) {
    return _firestore.collection('users').doc(uid).collection('events');
  }

  Stream<List<Event>> watchEvents(String uid) {
    return _events(uid)
        .orderBy('eventDateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Event.fromFirestore).toList());
  }

  Future<void> createEvent(String uid, Event event) {
    return _events(uid).add(event.toFirestore());
  }

  Future<void> updateEvent(String uid, Event event) {
    return _events(uid).doc(event.id).update(event.toFirestore());
  }

  Future<void> deleteEvent(String uid, String eventId) {
    return _events(uid).doc(eventId).delete();
  }
}