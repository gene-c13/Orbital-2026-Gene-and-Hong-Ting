import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/screens/social/create_post_screen.dart';
import 'package:after_hours/widgets/navigation_helper.dart';
import 'package:after_hours/screens/social/user_search_screen.dart';
import 'package:after_hours/services/post_service.dart';
import 'dart:async';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/screens/social/friend_requests_screen.dart';
import 'package:after_hours/widgets/post_card.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  List<QueryDocumentSnapshot> _visibleDocs = [];
  String? _currentUid;
  bool _initialLoad = true;
  bool _hasError = false;

  StreamSubscription? _feedSub;

  @override
  void initState() {
    super.initState();
    _currentUid = AuthService().currentUid;
    _subscribeToPosts();
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    super.dispose();
  }

  void _subscribeToPosts() {
    if (_currentUid == null) {
      setState(() { _visibleDocs = []; _initialLoad = false; });
      return;
    }

    _feedSub = PostService().feedStream(_currentUid!).listen(
      (docs) {
        if (mounted) setState(() { _visibleDocs = docs; _initialLoad = false; _hasError = false;});
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: buildNavBar(1, (i) { if (i != 1) goToTab(context, i); }),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SOCIAL',
                      style: kNectarine(size: 32, letterSpacing: 3),
                    ),
                   const Spacer(),
                   IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
                      ),
                      icon: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UserSearchScreen()),
                      ),
                      icon: const Icon(Icons.search, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: kAccent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 17),
                            SizedBox(width: 5),
                            Text(
                              'Log night',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: kBorder),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_initialLoad) {
      return const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2));
    }
    if (_hasError) {
      return const Center(
        child: Text('Something went wrong.', style: TextStyle(color: kMuted)),
      );
    }
    if (_visibleDocs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_outlined, color: kDim, size: 56),
            const SizedBox(height: 18),
            const Text(
              'No posts yet.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Be the first to log a night.', style: TextStyle(color: kDim, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: _visibleDocs.length,
      itemBuilder: (context, index) {
        final data = _visibleDocs[index].data() as Map<String, dynamic>;
        return PostCard(postId: _visibleDocs[index].id, data: data);

      },
    );
  }
}

