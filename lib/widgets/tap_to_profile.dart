import 'package:flutter/material.dart';
import 'package:after_hours/screens/social/other_user_profile_view.dart';

class TapToProfile extends StatelessWidget {
  final String uid;
  final Widget child;

  const TapToProfile({
    super.key, required this.uid, required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector( 
      behavior: HitTestBehavior.opaque,
      onTap: uid.isEmpty? null 
      : () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => 
    OtherUserProfileView(uid: uid)),
                  ),
        child: child, //gesturedetector always copies the size of the child 
        );
  }
}
