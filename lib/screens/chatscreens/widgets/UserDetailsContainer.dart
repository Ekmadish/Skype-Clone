import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skype_clone/models/user.dart';
import 'package:skype_clone/provider/user_provider.dart';
import 'package:skype_clone/resources/firebase_methods.dart';
import 'package:skype_clone/screens/chatscreens/widgets/ShimmeringLogo.dart';
import 'package:skype_clone/screens/chatscreens/widgets/cached_image.dart';
import 'package:skype_clone/screens/login_screen.dart';
import 'package:skype_clone/widget/appbar.dart';

class UserDetailsContainer extends StatelessWidget {
  const UserDetailsContainer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseMethods _auth = FirebaseMethods();
    signOut() async {
      final bool isLoggedOut = await _auth.signOut();

      if (isLoggedOut) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false);
      }
    }

    return Container(
      margin: EdgeInsets.only(top: 25),
      child: Column(
        children: [
          CustomAppBar(
            actions: <Widget>[
              FlatButton(
                onPressed: () => signOut(),
                child: Text(
                  "Sign out",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            ],
            centerTitle: true,
            leading: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
            title: ShimmeringLogo(),
          ),
          UserDetailsBody(),
        ],
      ),
    );
  }
}

class UserDetailsBody extends StatelessWidget {
  const UserDetailsBody({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    final User user = userProvider.getUser;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        children: [
          CachedImage(
            user.profilePhoto,
            isRound: true,
            radius: 50,
          ),
          SizedBox(
            width: 15,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                user.email,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
