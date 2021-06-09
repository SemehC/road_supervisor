import 'package:flutter/material.dart';
import 'package:intro_views_flutter/intro_views_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:road_supervisor/models/shared_prefs_manager.dart';

import '../main.dart';

class IntroPages extends StatefulWidget {
  IntroPages({Key? key}) : super(key: key);

  @override
  _IntroPagesState createState() => _IntroPagesState();
}

class _IntroPagesState extends State<IntroPages> {
  final pages = [
    PageViewModel(
      pageColor: const Color(0xFF03A9F4),
      mainImage: LottieBuilder.asset(
        "assets/lottie/car_bumping.json",
        animate: true,
        repeat: true,
        reverse: true,
      ),
      body: SingleChildScrollView(
        child: const Text(
          'An app dedicated to road status supervision',
        ),
      ),
      title: const Text(
        'Road Supervisor',
      ),
      titleTextStyle: const TextStyle(color: Colors.white),
      bodyTextStyle: const TextStyle(color: Colors.white),
    ),
    PageViewModel(
      pageColor: const Color(0xFF03A9F4),
      mainImage: LottieBuilder.asset(
        "assets/lottie/map_navigation.json",
        animate: true,
        repeat: true,
        reverse: true,
      ),
      body: SingleChildScrollView(
        child: const Text(
          'View local road status directly on your map',
        ),
      ),
      title: const Text(
        'Map',
      ),
      titleTextStyle: const TextStyle(color: Colors.white),
      bodyTextStyle: const TextStyle(color: Colors.white),
    ),
    PageViewModel(
      pageColor: const Color(0xFF03A9F4),
      mainImage: LottieBuilder.asset(
        "assets/lottie/encryption_animation.json",
        animate: true,
        repeat: true,
        reverse: true,
      ),
      body: SingleChildScrollView(
        child: const Text(
          'All provided data is encrypted and safely stored',
        ),
      ),
      title: const Text(
        'Security',
      ),
      titleTextStyle: const TextStyle(color: Colors.white),
      bodyTextStyle: const TextStyle(color: Colors.white),
    ),
    PageViewModel(
      pageColor: const Color(0xFF03A9F4),
      mainImage: LottieBuilder.asset(
        "assets/lottie/earth_and_connections.json",
        animate: true,
        repeat: true,
        reverse: true,
      ),
      body: SingleChildScrollView(
        child: const Text(
          'Thanks to a centralized database, view road status submitted by all our users',
        ),
      ),
      title: const Text(
        'Centralized',
      ),
      titleTextStyle: const TextStyle(color: Colors.white),
      bodyTextStyle: const TextStyle(color: Colors.white),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IntroViewsFlutter(
      pages,
      onTapDoneButton: () async {
        await SharedPrefsManager.setBool(key: "viewIntro", val: true);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
          (Route<dynamic> route) => false,
        );
      },
      showSkipButton: true,
      pageButtonTextStyles: TextStyle(
        color: Colors.white,
        fontSize: 18.0,
        fontFamily: 'Regular',
      ),
    );
  }
}
