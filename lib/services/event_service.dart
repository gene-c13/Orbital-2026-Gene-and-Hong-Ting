import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:after_hours/models/event.dart';

//this class fetches events from database and hands to screen

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _eventsCollection => _firestore.collection('events'); //get is like final that runs only when its called, not when the class is created
  //get means that event.eventsCollection will return _firestore.collection('events')
  //same as defining any normal field, its just required when value comes from another field in the same class and not a hardcoded value

  Stream<List<Event>> getEventsByDateStream(String date) {
    return _eventsCollection
        .where('date', isEqualTo: date) //filter out documents in the collection
        .orderBy('sort_order')
        .snapshots() //snapshots return a Stream<QuerySnapshot>
        .map((snap) => //first map: for every QuerySnapshot(box that contains list of docs) that arrives...
              snap.docs.map((d) =>  Event.fromFirestore(d.data() as Map<String, dynamic>, d.id)).toList());
  }      //second map: loop through every doc inside QuerySnapshot and transform into an Event
        //.docs gives a list of documents

  Stream<List<Event>> getAllEventsStream() {
    final sgt = DateTime.now().toUtc().add(const Duration(hours: 8));
    final todayKey = DateFormat('yyyy-MM-dd').format(sgt);

    return _eventsCollection
        .where('date', isGreaterThanOrEqualTo: todayKey)
        .orderBy('date')
        .orderBy('sort_order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Event.fromFirestore(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }
}
