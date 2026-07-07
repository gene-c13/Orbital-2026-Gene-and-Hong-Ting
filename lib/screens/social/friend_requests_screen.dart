import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/friend_service.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/widgets/user_avatar.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({super.key});

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
          Text('REQUESTS', style: kNectarine(size: 24, letterSpacing: 3)),
        ],
      ),
    ),
    Expanded(child: _friendRequestsSection(currentUid)),
  ],
),
        ),
      ),
    );
  }


  Widget _friendRequestsSection(String currentUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FriendService().incomingRequests(currentUid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { //data! means im sure data is not null, because we checked it already with hasData
          return const Center(
            child: Text('No requests yet.', style: TextStyle(color: kDim, fontSize: 15)),
          ); //sizedbox.shrink() just means return nothing
                  }

        final requests = snapshot.data!.docs; //store all requests documents (lists)
        final fromUids = requests
            .map((doc) => (doc.data() as Map<String, dynamic>)['from_uid'] as String) //document data is returned as a generic object, this tells Dart to treat it 
                                                                                      //as a key value map so can access fields by name
            .toList();

        // Fetch every requester's profile in one batched call instead of
        // firing a separate Firestore read per row.
        return FutureBuilder<List<AppUser>>(
          future: UserService().getUsers(fromUids),
          builder: (context, usersSnap) {
            if (!usersSnap.hasData) return const SizedBox.shrink(); //sizedbox.shrink() just means return nothing

            final usersByUid = <String, AppUser>{};
            for (final u in usersSnap.data!) {
              usersByUid[u.uid] = u;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),

                const SizedBox(height: 10),
                ...requests.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fromUid = data['from_uid'] as String;
                  final requester = usersByUid[fromUid];
                  final username = requester?.name ?? 'Unknown';

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
                          photoUrl: requester?.photoUrl,
                          displayName: username,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            username,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FriendService().rejectRequest(doc.id);
                          },
                          child: const Text('Decline', style: TextStyle(color: kMuted)),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FriendService().acceptRequest(doc.id, fromUid, currentUid);
                          },
                          child: const Text('Accept', style: TextStyle(color: kAccent, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 14),
              ],
            );
          },
        );
      },
    );
  }


}

