import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:after_hours/services/post_service.dart';
import 'package:after_hours/theme/app_theme.dart';

//shows a user's posts, filtered to what the viewer is allowed to see.
class UserPostsList extends StatelessWidget {
  const UserPostsList({
    super.key,
    required this.uid,
    required this.viewerUid,
    required this.itemBuilder,
  });

  final String uid;
  final String viewerUid;
  final Widget Function(BuildContext context, QueryDocumentSnapshot doc) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column( //a Column and not a ListView because the profile screen already scrolls,
//so this only needs to stack the cards and let the parent handle scrolling
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(10,0,0,4),
        child: Text(
          'Posts',
          style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900),
        ),
      ),
      StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: PostService().userPostsStream(viewerUid: viewerUid, profileUid: uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Couldn\'t load posts.', style: TextStyle(color: kMuted, fontSize: 13)),
            );
          }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2)),
          );
        }

        final docs = snapshot.data!;

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No posts yet', style: TextStyle(color: kDim))),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: docs.map((doc) => itemBuilder(context, doc)).toList(),
        );
      },
      )
    ]
    );
  }
}
