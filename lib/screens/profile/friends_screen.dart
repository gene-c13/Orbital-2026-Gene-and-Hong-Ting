import 'package:after_hours/models/user.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/services/friend_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/widgets/tap_to_profile.dart';
import 'package:after_hours/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/widgets/navigation_helper.dart';


class FriendsScreen extends StatelessWidget {
  
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUid ?? '';
    return Scaffold(
      body: Container(
        decoration: kBgDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Text('FRIENDS', style: kNectarine(size: 24, letterSpacing: 3)),
                  ],
                ),
              ),
              Expanded(child: _friendsList(currentUid)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _friendsList(String currentUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FriendService().friendsStream(currentUid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            child: const Text('No friends yet.', style: TextStyle(color: kDim, fontSize: 13)),
          );
        }

        final friendUids = snapshot.data!.docs.map((d) => d.id).toList();

        return FutureBuilder<List<AppUser>>(
          future: UserService().getUsers(friendUids),
          builder: (context, usersSnap) {
            if (!usersSnap.hasData) {
              return const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2));
            }

            final friends = usersSnap.data!;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: friends.map((friend) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TapToProfile(
                            uid: friend.uid,
                            child: Row(
                              children: [
                                UserAvatar(photoUrl: friend.photoUrl, displayName: friend.name, radius: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    friend.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => openChat(context, friend.uid, friend.name),
                          child: const Text('Message', style: TextStyle(color: kAccent, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}