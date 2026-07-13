import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:after_hours/services/post_service.dart';
import 'package:after_hours/theme/app_theme.dart';

/// Renders uid's posts, filtered to whatever viewerUid is allowed to see.
/// Drop this at the bottom of a profile screen, under the stats.
///
/// It's a plain ListView with shrinkWrap + no scrolling of its own, because
/// the profile screens already scroll the whole page via
/// SingleChildScrollView. shrinkWrap makes it size to its content instead
/// of trying to fill infinite height, and NeverScrollableScrollPhysics stops
/// it from fighting the outer scroll view for gesture control.
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
    return Column(
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

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) => itemBuilder(context, docs[index]),
        );
      },
      )
    ]
    );
  }
}
