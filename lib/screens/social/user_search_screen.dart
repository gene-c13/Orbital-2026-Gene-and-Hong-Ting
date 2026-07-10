import 'package:flutter/material.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/services/friend_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/widgets/user_avatar.dart';
import 'package:after_hours/widgets/navigation_helper.dart';
import 'package:after_hours/widgets/tap_to_profile.dart';
import 'dart:async';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _controller = TextEditingController();
  final _friendService = FriendService();
  final _currentUid = AuthService().currentUid ?? '';

  List<AppUser> _results = []; //list of AppUser
  bool _loading = false;
  String _lastQuery = ''; //rmb the last search
  Timer? _debounce; //countdown timer, Timer is an object that counts down and runs a function. ?means can be null, like at start where Timer isnt running yet

  @override
  void initState() { //runs exactly once when screen is created
    super.initState();
    _controller.addListener(_onChanged); //everytime controller notices a change, call the function inside addListener
  } //attack Listener when screen is created

  @override
  void dispose() { //when user navigates away, clean up removed widgets
    _debounce?.cancel(); //only call cancel if not null, if removed, will crash when user leaves before typing anything ie. _debounce is null
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() { //logic to cancel previous timer and start a fresh 300ms , fire search when timer expire
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      _debounce?.cancel();
      setState(() { _results = []; _loading = false; }); //clear the list to empty
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query)); //2 arguments, Timer(duration,fxn to run)
  } //cancel Timer and start a fresh one // this fxn runs because of initstate(refer to it)

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    _lastQuery = query;

    try {
      final all = await UserService().searchByUsernamePrefix(query);

      if (query != _lastQuery) return; // a newer search already in flight

      final results = all.where((u) => u.uid != _currentUid).toList();

      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      // search failed silently, results stay empty
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          Expanded(
            child: TapToProfile(
              uid: widget.uid,
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
                ],
              ),
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
                return TextButton(
                  onPressed: () => openChat(context, widget.uid, widget.username),
                  child: const Text('Message', style: TextStyle(color: kAccent, fontWeight: FontWeight.w700)),
                );
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