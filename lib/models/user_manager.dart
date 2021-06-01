import 'package:firebase_auth/firebase_auth.dart';
import 'package:road_supervisor/main.dart';
import 'package:road_supervisor/models/user_profile.dart';

class UserManager {
  static UserProfile currentUserProfile =
      UserProfile(photoUrl: "", fullName: "", carType: "");
  static User? currentUser;

  static fetchUserInfo() async {
    currentUserProfile =
        UserProfile.parseDoc(await usersRef.doc(currentUser!.uid).get());
    print("Got user info");
  }

  static updateUserInfo(field, value) async {
    return usersRef
        .doc(currentUser!.uid)
        .update({field: value})
        .then((value) => print("User Updated"))
        .catchError((error) => print("Failed to update user: $error"));
  }
}
