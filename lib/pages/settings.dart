import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_switch/flutter_switch.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ndialog/ndialog.dart';
import 'package:menu_button/menu_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:road_supervisor/generated/codegen_loader.g.dart';
import 'package:road_supervisor/main.dart';
import 'package:road_supervisor/models/shared_prefs_manager.dart';
import 'package:road_supervisor/models/user_manager.dart';
import 'package:road_supervisor/pages/login_signup.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:easy_localization/easy_localization.dart';

class MySettingsWidget extends StatefulWidget {
  MySettingsWidget({Key? key}) : super(key: key);

  @override
  _MySettingsWidgetState createState() => _MySettingsWidgetState();
}

class _MySettingsWidgetState extends State<MySettingsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getUserDataField();
  }

  setLanguage(String value) {
    setState(() {
      SharedPrefsManager.setString(key: LANGUAGE, val: value);
    });

    switch (value) {
      case "English":
        {
          context.locale = Locale('en', 'US');
        }
        break;
      case "Français":
        {
          context.locale = Locale('fr', 'FR');
        }
        break;
      default:
        {
          context.locale = Locale('en', 'US');
        }
        break;
    }
  }

  setBool(String key, bool value) {
    setState(() {
      SharedPrefsManager.setBool(key: key, val: value);
    });
  }

  Future<void> updateUser(field, value) {
    return UserManager.updateUserInfo(field, value);
  }

  getUserDataField() async {
    print("Getting user info");
    if (UserManager.currentUserProfile == null)
      await UserManager.fetchUserInfo();
    print(UserManager.currentUserProfile.fullName);
    fullName = UserManager.currentUserProfile.fullName;
    email = UserManager.currentUser!.email!;
    photoUrl = UserManager.currentUserProfile.photoUrl;
  }

  buildLoadingScreen() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: lottie.Lottie.asset(
        "assets/lottie/gps_sattelite_orbit.json",
        animate: true,
        repeat: true,
        reverse: true,
        alignment: Alignment.center,
      ),
    );
  }

  copyImageToAppDirectory(File pic) async {
    var oldImageIndex = imageIndex;
    final appDir = await getExternalStorageDirectory();
    final picPath = Directory(appDir!.path + "/Pictures");
    var picName = pic.path.split("/").last;
    var newPic =
        await pic.copy(picPath.path + "/profilePicture${++imageIndex}.jpg");
    SharedPrefsManager.setInt(key: IMAGE_INDEX, val: imageIndex);
    setState(() {
      imageCache!.clear();
      imageCache!.clearLiveImages();
      shownProfilePicture = newPic;
      UserManager.loadProfileImage();
    });
    print("Deleting picture $oldImageIndex");
    print("New image is $imageIndex");
    File(picPath.path + "/profilePicture$oldImageIndex.jpg").delete();
    File(picPath.path + "/" + picName).delete();
  }

  handleChangePicture() async {
    final pickedFile =
        await picker.getImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      SharedPrefsManager.setBool(key: HAS_LOCAL_IMAGE, val: true);
      copyImageToAppDirectory(File(pickedFile.path));
      var ref = storageRef
          .child("${UserManager.currentUser!.uid}_profile.jpg")
          .putFile(File(pickedFile.path))
          .then((snapshot) async {
        String downUrl = await snapshot.ref.getDownloadURL();
        print("New download URL = ${downUrl}");
        UserManager.updateUserInfo(
          PHOTO_URL,
          downUrl,
        );
        setState(() {
          hasLocalImage = true;
          photoUrl = downUrl;
        });
      });
      //print("New download URL = $downUrl");

      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(msg: LocaleKeys.Canceled.tr());
    }
  }

  buildImageZoom() async {
    await NAlertDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text("Image"),
      content: Container(
        width: 300,
        height: 300,
        child: UserManager.getProfileImage(false),
      ),
      actions: [
        FlatButton(
            child: Text(LocaleKeys.Cancel.tr()),
            onPressed: () {
              Navigator.pop(context);
            }),
        FlatButton(
            child: Text(LocaleKeys.Change.tr()),
            onPressed: () {
              handleChangePicture();
            }),
      ],
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  buildUsernameAndPhoto() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(8.0),
      color: Theme.of(context).primaryColor,
      child: ListTile(
        onTap: () {
          showNamePopup();
        },
        title: Text(
          fullName!,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        leading: GestureDetector(
            onTap: () {
              buildImageZoom();
            },
            child: UserManager.getProfileImage(true)),
        trailing: Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),
    );
  }

  buildAccountSettingsCard() {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Column(
        children: <Widget>[
          ListTile(
            leading: Icon(
              Icons.lock_outline,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(LocaleKeys.ChangePassword.tr()),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {
              showPasswordPopup();
            },
          ),
          divider(),
          ListTile(
            leading: Icon(
              Icons.mail_outline,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(LocaleKeys.ChangeEmail.tr()),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {
              showEmailPopup();
            },
          ),
          divider(),
          ListTile(
            leading: Icon(
              Icons.language_outlined,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(LocaleKeys.ChangeLanguage.tr()),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {
              showLanguagePopup();
            },
          )
        ],
      ),
    );
  }

  buildNotificationsSetting() {
    return Container(
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(LocaleKeys.ReceiveNotifications.tr(),
            style: TextStyle(
              fontSize: 16.5,
            )),
        FlutterSwitch(
          width: 100.0,
          height: 35.0,
          valueFontSize: 18.0,
          toggleSize: 45.0,
          value: receiveNotifications!,
          borderRadius: 30.0,
          padding: 8.0,
          inactiveColor: Theme.of(context).primaryColor,
          activeColor: Theme.of(context).primaryColor,
          activeText: LocaleKeys.Yes.tr(),
          inactiveText: LocaleKeys.No.tr(),
          showOnOff: true,
          onToggle: (val) {
            setState(() {
              receiveNotifications = val;
              setBool(RECEIVE_NOTIFICATIONS, receiveNotifications!);
            });
          },
        ),
      ]),
      margin: const EdgeInsets.only(bottom: 10),
    );
  }

  buildSpeedSetting() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(LocaleKeys.SpeedUnit.tr(),
          style: TextStyle(
            fontSize: 16.5,
          )),
      FlutterSwitch(
        width: 100.0,
        height: 35.0,
        valueFontSize: 18.0,
        toggleSize: 45.0,
        value: speedUnit!,
        borderRadius: 30.0,
        padding: 8.0,
        inactiveColor: Theme.of(context).primaryColor,
        activeColor: Theme.of(context).primaryColor,
        activeText: "KMH",
        inactiveText: "MPH",
        showOnOff: true,
        onToggle: (val) {
          setState(() {
            speedUnit = val;
            setBool(SPEED_UNIT, speedUnit!);
          });
        },
      ),
    ]);
  }

  buildLogoutButton() {
    return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(8, 40, 8, 8),
        color: Theme.of(context).primaryColor,
        child: ListTile(
          leading: Icon(
            Icons.logout_outlined,
            color: Theme.of(context).secondaryHeaderColor,
          ),
          title: Text(
            LocaleKeys.LogOut.tr(),
            style: TextStyle(color: Theme.of(context).secondaryHeaderColor),
          ),
          trailing: Icon(
            Icons.keyboard_arrow_right,
            color: Theme.of(context).secondaryHeaderColor,
          ),
          onTap: () {
            showLogOutPopup();
          },
        ));
  }

  buildUserInfoScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildUsernameAndPhoto(),
          const SizedBox(height: 10.0),
          buildAccountSettingsCard(),
          const SizedBox(height: 10),
          Text(
            LocaleKeys.NotificationSettings.tr(),
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor),
          ),
          buildNotificationsSetting(),
          const SizedBox(height: 10),
          Text(
            LocaleKeys.SpeedSettings.tr(),
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor),
          ),
          buildSpeedSetting(),
          buildLogoutButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: Stack(
          children: [
            if (!gotUserData) buildLoadingScreen(),
            if (gotUserData) buildUserInfoScreen(),
          ],
        ));
  }

  Container divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      height: 1.0,
      color: Colors.grey,
    );
  }

  void logOut() {
    auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => LoginSignup(),
      ),
      (route) => false,
    );
  }

  Future<void> showPasswordPopup() async {
    await NAlertDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text(LocaleKeys.ChangingPassword.tr()),
      content: Container(
        height: 135,
        child: Column(
          children: [
            Text(LocaleKeys.Password8Chars.tr()),
            TextField(
              decoration: InputDecoration(
                  border: new UnderlineInputBorder(
                      borderSide: new BorderSide(
                          color: Theme.of(context).primaryColor)),
                  hintText: LocaleKeys.Password.tr()),
              obscureText: true,
              onChanged: (value) {
                password = value;
              },
            ),
            TextField(
              decoration: InputDecoration(
                  border: new UnderlineInputBorder(
                      borderSide: new BorderSide(
                          color: Theme.of(context).primaryColor)),
                  hintText: LocaleKeys.ConfirmPassword.tr()),
              obscureText: true,
              onChanged: (value) {
                confirmPassword = value;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
            child: Text(LocaleKeys.Cancel.tr()),
            onPressed: () {
              Navigator.pop(context);
            }),
        FlatButton(
            child: Text(LocaleKeys.Confirm.tr()),
            onPressed: () {
              checkPassword();
            }),
      ],
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  Future<void> showLogOutPopup() async {
    await NAlertDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text(LocaleKeys.LoggingOut.tr()),
      content: Container(
        height: 30,
        child: Column(
          children: [
            Text(LocaleKeys.LogOutPrompt.tr()),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
            child: Text(LocaleKeys.No.tr()),
            onPressed: () {
              Navigator.pop(context);
            }),
        FlatButton(
            child: Text(LocaleKeys.Yes.tr()),
            onPressed: () {
              logOut();
            }),
      ],
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  Future<void> showEmailPopup() async {
    await NAlertDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text(LocaleKeys.ChangingEmail.tr()),
      content: Container(
        height: 70,
        child: Column(
          children: [
            Text(LocaleKeys.EnterEmail.tr()),
            TextFormField(
              initialValue: email,
              decoration: InputDecoration(
                  border: new UnderlineInputBorder(
                      borderSide: new BorderSide(
                          color: Theme.of(context).primaryColor)),
                  hintText: 'Email'),
              onChanged: (value) {
                email = value;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
            child: Text(LocaleKeys.Cancel.tr()),
            onPressed: () {
              Navigator.pop(context);
            }),
        FlatButton(
            child: Text(LocaleKeys.Confirm.tr()),
            onPressed: () {
              checkEmail();
            }),
      ],
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  Future<void> showLanguagePopup() async {
    final Widget normalChildButton = SizedBox(
      width: 93,
      height: 40,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
                child:
                    Text(selectedLanguage!, overflow: TextOverflow.ellipsis)),
            const SizedBox(
              width: 16,
              height: 17,
              child: FittedBox(
                fit: BoxFit.fill,
                child: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await NAlertDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text(LocaleKeys.ChangingLanguage.tr()),
      content: Container(
        height: 80,
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: Text(LocaleKeys.EnterLanguage.tr())),
            MenuButton<String>(
              child: normalChildButton,
              items: UserManager.languages,
              itemBuilder: (String value) => Container(
                height: 40,
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16),
                child: Text(value),
              ),
              toggledChild: Container(
                child: normalChildButton,
              ),
              onItemSelected: (String value) {
                setState(() {
                  selectedLanguage = value;
                  setLanguage(selectedLanguage!);
                  Navigator.pop(context);
                });
              },
            )
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
            child: Text(LocaleKeys.Cancel.tr()),
            onPressed: () {
              Navigator.pop(context);
            }),
      ],
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  Future<void> showNamePopup() async {
    await NAlertDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text(LocaleKeys.ChangingName.tr()),
      content: Container(
        height: 70,
        child: Column(
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [Text(LocaleKeys.EnterName.tr())]),
            TextFormField(
                initialValue: fullName,
                decoration: InputDecoration(
                    border: new UnderlineInputBorder(
                        borderSide: new BorderSide(
                            color: Theme.of(context).primaryColor)),
                    hintText: 'Name'),
                onChanged: (value) {
                  setState(() {
                    fullName = value;
                  });
                }),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
            child: Text(LocaleKeys.Cancel.tr()),
            onPressed: () {
              Navigator.pop(context);
            }),
        FlatButton(
            child: Text(LocaleKeys.Confirm.tr()),
            onPressed: () {
              checkName();
            }),
      ],
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  void checkName() {
    if (fullName!.length < 3) {
      Fluttertoast.showToast(
          msg: LocaleKeys.ShortName.tr(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).errorColor);
    } else {
      Fluttertoast.showToast(
          msg: LocaleKeys.NameChanged.tr(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).primaryColor);
      updateUser(FULL_NAME, fullName);
      Navigator.pop(context);
    }
  }

  void checkPassword() {
    if (confirmPassword == password && password!.length >= 8) {
      Fluttertoast.showToast(
          msg: LocaleKeys.PasswordChanged.tr(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).primaryColor);
      auth.currentUser!.updatePassword(password!);
      Navigator.pop(context);
    } else if (confirmPassword != password && password!.length >= 8) {
      Fluttertoast.showToast(
          msg: LocaleKeys.PasswordMatch.tr(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).errorColor);
    } else if (confirmPassword == password && password!.length < 8) {
      Fluttertoast.showToast(
          msg: LocaleKeys.ShortPassword.tr(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).errorColor);
    } else {
      Fluttertoast.showToast(
          msg: LocaleKeys.VerifyPassword.tr(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).errorColor);
    }
  }

  Future<void> checkEmail() async {
    bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email!);
    if (emailValid) {
      try {
        await auth.currentUser!.updateEmail(email!);
        Fluttertoast.showToast(
            msg: LocaleKeys.EmailChanged.tr(),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Theme.of(context).primaryColor);
      } on FirebaseAuthException catch (e) {
        Fluttertoast.showToast(
            msg: "${e.message}",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Theme.of(context).primaryColor);
      }
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
          msg: LocaleKeys.VerifyEmail.tr(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).errorColor);
    }
  }
}
