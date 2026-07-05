import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/chat_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/screens/chat/chat_screen.dart';
import 'package:after_hours/widgets/user_avatar.dart';

class ChatListScreen extends StatelessWidget { //stateless because the streambuilder handles its own live updates internally
  const ChatListScreen({super.key}); //identify the widget so it can track it across rebuilds

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Text('MESSAGES', style: kNectarine(size: 24, letterSpacing: 3)),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: kBorder),
              Expanded(
                child: StreamBuilder<QuerySnapshot>( //StreamBuilder is a widget that rebuilds its UI every time new data arrives on a stream
                  stream: ChatService().userChatsStream(currentUid),
                  builder: (context, snapshot) { 
                    if (snapshot.connectionState == ConnectionState.waiting) { //show spinner while Firestore fetches first batch of data
                      return const Center(
                        child: CircularProgressIndicator(color: kAccent, strokeWidth: 2),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, color: kDim, size: 52),
                            const SizedBox(height: 16),
                            const Text(
                              'No messages yet.',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Find someone on the social tab to message.',
                              style: TextStyle(color: kDim, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    // collect the other-user uid from each chat doc
                    final otherUids = docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final participants = List<String>.from(d['participants'] ?? []);
                      return participants.firstWhere(
                        (uid) => uid != currentUid,
                        orElse: () => '',
                      );
                    }).where((uid) => uid.isNotEmpty).toList();

                    // one batch fetch for all participants, not one per row
                    return FutureBuilder<List<AppUser>>(
                      future: UserService().getUsers(otherUids),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(color: kAccent, strokeWidth: 2),
                          );
                        }

                        final userMap = {for (final u in userSnap.data!) u.uid: u};

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final participants = List<String>.from(data['participants'] ?? []);
                            final otherUid = participants.firstWhere(
                              (uid) => uid != currentUid,
                              orElse: () => '',
                            );
                            final other = userMap[otherUid];
                            if (other == null) return const SizedBox.shrink();

                            final lastMessage = data['last_message'] as String? ?? '';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              leading: UserAvatar(displayName: other.name, photoUrl: other.photoUrl, radius: 24),
                              title: Text(
                                other.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                lastMessage.isEmpty ? '@${other.username}' : lastMessage,
                                style: const TextStyle(color: kDim, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    otherUid:         otherUid,
                                    otherDisplayName: other.name,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}