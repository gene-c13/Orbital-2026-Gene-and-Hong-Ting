import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/services/chat_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/widgets/user_avatar.dart';
import 'package:after_hours/widgets/navigation_helper.dart';
import 'package:after_hours/widgets/tap_to_profile.dart';


class ChatListScreen extends StatelessWidget { //stateless because the streambuilder handles its own live updates internally
  const ChatListScreen({super.key}); //identify the widget so it can track it across rebuilds

  // the participant in a chat doc that isn't me: used both when collecting
  // uids for the batch fetch and when building each row
  String _otherUid(Map<String, dynamic> chatData, String currentUid) {
    final participants = List<String>.from(chatData['participants'] ?? []);
    return participants.firstWhere((uid) => uid != currentUid, orElse: () => '');
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUid ?? '';

    return Scaffold(
      bottomNavigationBar: buildNavBar(2, (i) { if (i != 2) goToTab(context, i); }),
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
                    if (snapshot.hasError) return Center(child: SelectableText('${snapshot.error}'));
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
                    final otherUids = docs
                        .map((doc) => _otherUid(doc.data() as Map<String, dynamic>, currentUid))
                        .where((uid) => uid.isNotEmpty)
                        .toList();

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
                            final otherUid = _otherUid(data, currentUid);
                            final other = userMap[otherUid];
                            if (other == null) return const SizedBox.shrink();

                            final lastMessage = data['last_message'] as String? ?? '';
                            final lastSender = data['last_sender_uid'] as String? ?? '';
                            final isMine = lastSender == currentUid;

                            final preview = lastMessage.isEmpty
                              ? '@${other.username}'
                              : isMine ? 'You: $lastMessage' : lastMessage;

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: kCardDecoration,
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                  leading: TapToProfile(
                                    uid: otherUid,
                                    child: UserAvatar(displayName: other.name, photoUrl: other.photoUrl, radius: 24),
                                  ),
                                  title: Text(
                                    other.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text(
                                    preview,
                                    style: const TextStyle(color: kDim, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => openChat(context, other.uid, other.username),
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