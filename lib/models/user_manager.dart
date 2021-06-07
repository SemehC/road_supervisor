import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:road_supervisor/main.dart';
import 'package:road_supervisor/models/shared_prefs_manager.dart';
import 'package:road_supervisor/models/user_profile.dart';

class UserManager {
  static Image? profileImage;
  static CircleAvatar? roundedProfileImage;
  static UserProfile currentUserProfile =
      UserProfile(photoUrl: "", fullName: "", carType: "");
  static User? currentUser;

  static fetchUserInfo() async {
    currentUser = auth.currentUser;
    currentUserProfile =
        UserProfile.parseDoc(await usersRef.doc(currentUser!.uid).get());
    photoUrl = currentUserProfile.photoUrl;
    print("Got user info and photUrl = ${currentUserProfile.photoUrl}");
  }

  static List<String> languages = <String>[
    'English',
    'Français',
  ];
  static updateUserInfo(field, value) async {
    switch (field) {
      case "FullName":
        {
          currentUserProfile.fullName = value;
        }
        break;
      case "CarType":
        {
          currentUserProfile.carType = value;
        }
        break;
      case "joinDate":
        {
          currentUserProfile.joinDate = value;
        }
        break;
      case "photoUrl":
        {
          currentUserProfile.photoUrl = value;
        }
    }
    return usersRef
        .doc(currentUser!.uid)
        .update({field: value})
        .then((value) => print("User Updated"))
        .catchError((error) => print("Failed to update user: $error"));
  }

  static getLocalSettings(State s) async {
    await fetchUserInfo();
    s.setState(() {
      //speed unit ==> kmh = true, mph = false
      if (speedUnit == null)
        speedUnit =
            SharedPrefsManager.getBool(key: SPEED_UNIT, defaultVal: true);
      if (receiveNotifications == null) {
        receiveNotifications = SharedPrefsManager.getBool(
            key: RECEIVE_NOTIFICATIONS, defaultVal: false);
      }
      if (selectedLanguage == null) {
        selectedLanguage = SharedPrefsManager.getString(
            key: LANGUAGE, defaultVal: languages[0]);
      }
      if (hasLocalImage == null) {
        hasLocalImage =
            SharedPrefsManager.getBool(key: HAS_LOCAL_IMAGE, defaultVal: false);
      }
      if (imageIndex == null) {
        imageIndex = SharedPrefsManager.getInt(key: IMAGE_INDEX, defaultVal: 0);
      }
      print("Has local image = " + hasLocalImage.toString());
      if (hasLocalImage!) {
        getLocalImage(s);
      } else {
        shownProfilePicture = null;
        print("Loading image from internet ..");
      }
      UserManager.loadProfileImage();
    });
    gotUserData = true;
  }

  static getImageProvider() {
    if (shownProfilePicture != null) {
      return FileImage(shownProfilePicture!);
    } else {
      print("Photo url : $photoUrl");
      return NetworkImage(
          photoUrl != "" ? photoUrl! : 'https://picsum.photos/seed/867/600');
    }
  }

  static getLocalImage(State s) async {
    final appDir = await getExternalStorageDirectory();
    final picPath = Directory(appDir!.path + "/Pictures");
    var pic = File(picPath.listSync().first.path);
    s.setState(() {
      if (shownProfilePicture == null) shownProfilePicture = pic;
    });
  }

  static loadProfileImage() {
    profileImage = Image(
      image: UserManager.getImageProvider(),
    );
    roundedProfileImage =
        CircleAvatar(backgroundImage: UserManager.getImageProvider());
  }

  static getProfileImage(bool rounded) {
    if (rounded) {
      return roundedProfileImage;
    }
    return profileImage;
  }

  static Future<List<Address>> fetchCurrentLocation() async {
    var loc = await Geolocator.getCurrentPosition();
    return await Geocoder.local
        .findAddressesFromCoordinates(Coordinates(loc.latitude, loc.longitude));
  }
}
