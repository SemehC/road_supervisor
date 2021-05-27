import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:road_supervisor/pages/login_signup.dart';
import 'package:road_supervisor/pages/main_layout.dart';

var usersRef = FirebaseFirestore.instance.collection("users");
final GoogleSignIn googleSignIn = GoogleSignIn();
FirebaseAuth auth = FirebaseAuth.instance;
late List<CameraDescription> cameras;

User? currentUser = null;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  cameras = await availableCameras();
  await checkIfLoggedIn();
  runApp(MyApp());
}

bool isLoggedIn = false;

checkIfLoggedIn() async {
  currentUser = auth.currentUser;
  isLoggedIn = currentUser != null;
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Road Supervisor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: !isLoggedIn ? LoginSignup() : MainLayout(),
    );
  }
}
