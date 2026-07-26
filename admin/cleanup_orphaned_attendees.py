import firebase_admin
from firebase_admin import credentials, firestore


def init_firestore():
    if not firebase_admin._apps:
        cred = credentials.Certificate('scraper/serviceAccountKey.json')
        firebase_admin.initialize_app(cred)
    return firestore.client()


def cleanup_orphaned_attendees():
    db = init_firestore()

    removed = 0
    checked = 0

    for event in db.collection('events').stream():
        attendees_ref = event.reference.collection('attendees')

        for attendee in attendees_ref.stream():
            checked += 1
            uid = attendee.id

            # attendee doc id is the uid: if there's no matching user
            # profile left, this is a ghost left over from a deleted account
            user_doc = db.collection('users').document(uid).get()
            if not user_doc.exists:
                attendee.reference.delete()
                removed += 1
                print(f"  removed ghost attendee {uid} from event {event.id}")

    print(f"Checked {checked} attendee entries, removed {removed} orphaned ones.")


if __name__ == "__main__":
    cleanup_orphaned_attendees()
