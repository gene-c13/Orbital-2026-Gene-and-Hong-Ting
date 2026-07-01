import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/services/friend_service.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/widgets/user_avatar.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _controller = TextEditingController();
  final _friendService = FriendService();
  final _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<AppUser> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    _search(query);
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(8)
        .get();

    final results = snapshot.docs
        .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
        .where((user) => user.uid != _currentUid)
        .toList();

    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: 'Search username...',
                          hintStyle: const TextStyle(color: Color(0x80FFFFFF)),
                          filled: true,
                          fillColor: const Color(0x26FFFFFF),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 1, color: kBorder),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: CircularProgressIndicator(color: kAccent, strokeWidth: 2),
                )
              else if (_controller.text.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Search for a user by username.', style: TextStyle(color: kDim)),
                  ),
                )
              else if (_results.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No users found.', style: TextStyle(color: kMuted)),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final user = _results[index];

                      return _UserResultTile(
                        uid: user.uid,
                        username: user.username,
                        photoUrl: user.photoUrl,
                        currentUid: _currentUid,
                        friendService: _friendService,
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

class _UserResultTile extends StatefulWidget {
  final String uid;
  final String username;
  final String? photoUrl;
  final String currentUid;
  final FriendService friendService;

  const _UserResultTile({
    required this.uid,
    required this.username,
    this.photoUrl,
    required this.currentUid,
    required this.friendService,
  });

  @override
  State<_UserResultTile> createState() => _UserResultTileState();
}

class _UserResultTileState extends State<_UserResultTile> {
  bool _requestSent = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          UserAvatar(
            photoUrl: widget.photoUrl,
            displayName: widget.username,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.username,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          FutureBuilder<List<bool>>(
            future: Future.wait([
              widget.friendService.isFriend(widget.currentUid, widget.uid),
              widget.friendService.hasPendingRequest(widget.currentUid, widget.uid),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final alreadyFriend = snapshot.data![0];
              final pending = snapshot.data![1] || _requestSent;

              if (alreadyFriend) {
                return const Text('Friends', style: TextStyle(color: kMuted, fontWeight: FontWeight.w600));
              }

              if (pending) {
                return const Text('Sent', style: TextStyle(color: kMuted, fontWeight: FontWeight.w600));
              }

              return TextButton(
                onPressed: () async {
                  await widget.friendService.sendFriendRequest(widget.currentUid, widget.uid);
                  setState(() => _requestSent = true);
                },
                child: const Text('Add', style: TextStyle(color: kAccent, fontWeight: FontWeight.w700)),
              );
            },
          ),
        ],
      ),
    );
  }
}