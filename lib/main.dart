import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:road_supervisor/models/database_manager.dart';
import 'package:road_supervisor/models/shared_prefs_manager.dart';
import 'package:road_supervisor/models/user_manager.dart';
import 'package:road_supervisor/pages/intro_pages.dart';
import 'package:road_supervisor/pages/login_signup.dart';
import 'package:road_supervisor/pages/main_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:road_supervisor/generated/codegen_loader.g.dart';

var usersRef = FirebaseFirestore.instance.collection("users");
final GoogleSignIn googleSignIn = GoogleSignIn();
final storageRef = FirebaseStorage.instance.ref();
FirebaseAuth auth = FirebaseAuth.instance;
late List<CameraDescription> cameras;
bool viewedIntro = false;
User? currentUser = null;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseManager.initializeDatabase();
  await Firebase.initializeApp();
  await SharedPrefsManager.initializeSharedPrefs();
  checkIfViewedIntro();
  cameras = await availableCameras();
  await checkIfLoggedIn();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
        supportedLocales: [Locale('en', 'US'), Locale('fr', 'FR')],
        path:
            'assets/translations', // <-- change the path of the translation files
        fallbackLocale: Locale('en', 'US'),
        child: MyApp()),
  );
}

bool isLoggedIn = false;

checkIfLoggedIn() async {
  currentUser = auth.currentUser;
  isLoggedIn = currentUser != null;
  if (isLoggedIn) UserManager.currentUser = currentUser;
}

checkIfViewedIntro() {
  print("Checking if viewed intor ");
  viewedIntro = SharedPrefsManager.getBool(key: "viewIntro", defaultVal: false);
  print(viewedIntro);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: LocaleKeys.AppName.tr(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: !viewedIntro
          ? IntroPages()
          : isLoggedIn
              ? MainLayout()
              : LoginSignup(),
    );
  }
}
