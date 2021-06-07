import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:road_supervisor/main.dart';
import 'package:road_supervisor/models/user_manager.dart';
import 'package:road_supervisor/pages/main_layout.dart';

class LoginSignup extends StatefulWidget {
  LoginSignup({Key? key}) : super(key: key);

  @override
  _LoginSignupState createState() => _LoginSignupState();
}

class _LoginSignupState extends State<LoginSignup> {
  Future<String?>? _authUser(LoginData data) async {
    try {
      var x = await auth.signInWithEmailAndPassword(
          email: data.name, password: data.password);
      currentUser = x.user;
      UserManager.getLocalSettings(this);
    } on FirebaseAuthException catch (e) {
      return (e.message);
    }

    return null;
  }

  Future<String?>? _signupUser(LoginData data) async {
    try {
      var x = await auth.createUserWithEmailAndPassword(
          email: data.name, password: data.password);
      await usersRef.doc(x.user!.uid).set({
        "FullName": null,
        "CarType": null,
        "photoUrl": null,
        "CreationTime": DateTime.now(),
      });
      currentUser = x.user;
      UserManager.currentUser = currentUser;
    } on FirebaseAuthException catch (e) {
      return (e.message);
    }
    return null;
  }

  Future<String?>? _recoverPassword(String name) async {
    try {
      await auth.sendPasswordResetEmail(email: name);
    } on FirebaseAuthException catch (e) {
      return (e.message);
    }

    return "Email sent";
  }

  animationCompleted() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => MainLayout(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      onSignup: _signupUser,
      onLogin: _authUser,
      onRecoverPassword: _recoverPassword,
      onSubmitAnimationCompleted: animationCompleted,
    );
  }
}
