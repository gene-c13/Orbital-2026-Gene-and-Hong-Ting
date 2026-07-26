import firebase_admin
from firebase_admin import credentials, auth, firestore


def init_firestore():
    if not firebase_admin._apps:
        cred = credentials.Certificate('scraper/serviceAccountKey.json')
        firebase_admin.initialize_app(cred)
    return firestore.client()


def delete_subcollection(doc_ref, subcollection_name):
    # deleting a document does NOT delete its subcollections: each doc inside
    # has to be deleted one by one
    for doc in doc_ref.collection(subcollection_name).stream():
        doc.reference.delete()


def delete_user(username):
    db = init_firestore()

    username_ref = db.collection('usernames').document(username)
    username_doc = username_ref.get()
    if not username_doc.exists:
        print(f"No user found with username '{username}'")
        return

    uid = username_doc.to_dict()['uid']
    print(f"Deleting user '{username}' ({uid})...")

    # this user's posts, and each post's own comments subcollection
    for post in db.collection('posts').where('uid', '==', uid).stream():
        delete_subcollection(post.reference, 'comments')
        post.reference.delete()
    print("  posts deleted")

    # friend requests they sent or received
    sent = db.collection('friend_requests').where('from_uid', '==', uid).stream()
    received = db.collection('friend_requests').where('to_uid', '==', uid).stream()
    for req in list(sent) + list(received):
        req.reference.delete()
    print("  friend requests deleted")

    # chats they were part of, and each chat's messages subcollection
    for chat in db.collection('chats').where('participants', 'array_contains', uid).stream():
        delete_subcollection(chat.reference, 'messages')
        chat.reference.delete()
    print("  chats deleted")

    # friendship is stored on both sides: remove this user from each friend's
    # list too, then delete their own friends subcollection
    user_ref = db.collection('users').document(uid)
    for friend in user_ref.collection('friends').stream():
        db.collection('users').document(friend.id).collection('friends').doc(uid).delete()
    delete_subcollection(user_ref, 'friends')
    print("  friend list entries deleted")

    # "going" markers live under events/{eventId}/attendees/{uid}: one doc per
    # event this user RSVP'd to. The doc id is the uid, so we don't need to
    # query for it, just try to delete it from every event. delete() on a doc
    # that doesn't exist is a no-op, so this is safe to run for every event.
    for event in db.collection('events').stream():
        event.reference.collection('attendees').document(uid).delete()
    print("  event attendance entries deleted")

    # the profile itself, and the username reservation
    user_ref.delete()
    username_ref.delete()
    print("  user profile + username reservation deleted")

    # the actual sign-in account: wrapped in try/except since it may already be
    # gone if you deleted it from Firebase Auth before running this script
    try:
        auth.delete_user(uid)
        print("  auth account deleted")
    except auth.UserNotFoundError:
        print("  auth account already gone")

    print(f"Done — '{username}' fully removed.")


if __name__ == "__main__":
    username = input("Username to delete: ").strip()
    confirm = input(f"Type it again to confirm deleting '{username}': ").strip()
    if confirm == username:
        delete_user(username)
    else:
        print("Confirmation didn't match — nothing deleted.")