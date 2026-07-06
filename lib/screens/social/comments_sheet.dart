import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/services/post_service.dart';
import 'package:after_hours/utils/time_format.dart';
import 'package:after_hours/screens/social/other_user_profile_view.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/widgets/user_avatar.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;
  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final auth = AuthService();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _sending = true);
    final username = auth.currentDisplayName;
    final appUser = await UserService().getUser(user.uid);


    try {
      await PostService().addComment(widget.postId, user.uid, username, text, appUser?.photoUrl);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comment error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = (media.size.height * 0.7 - media.viewInsets.bottom).clamp(200.0, media.size.height);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: kSheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Text('Comments',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            const Divider(height: 1, color: kBorder),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: PostService().commentsStream(widget.postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2)),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No comments yet. Say something.',
                            style: TextStyle(color: kDim, fontSize: 14)),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, i) =>
                        _commentTile(docs[i].data() as Map<String, dynamic>),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: kBorder),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        cursorColor: kAccent,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: const TextStyle(color: kDim),
                          filled: true,
                          fillColor: kSurface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: kAccent, strokeWidth: 2)),
                          )
                        : IconButton(
                            onPressed: _send,
                            icon: const Icon(Icons.send, color: kAccent),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _commentTile(Map<String, dynamic> c) {
    final uid = c['uid'] as String? ?? ''; //give me the uid but if null give me ''
    final username = c['username'] as String? ?? 'Clubber';
    final text = c['text'] as String? ?? '';
    final photoUrl = c['photo_url'] as String?;
    final ts = c['created_at'] as Timestamp?;

    void openProfile() { //defining function that opens other user's profile
      if (uid.isEmpty) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OtherUserProfileView(uid: uid)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector( //detects tap
            onTap: openProfile,
            child: UserAvatar(photoUrl: photoUrl, displayName: username, radius: 16),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: openProfile,
                      child: Text(username,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    Text(timeAgo(ts), style: const TextStyle(color: kDim, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





