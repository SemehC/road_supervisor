import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ndialog/ndialog.dart';
import 'package:menu_button/menu_button.dart';
import 'package:road_supervisor/main.dart';
import 'package:road_supervisor/pages/login_signup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MySettingsWidget extends StatefulWidget {
  MySettingsWidget({Key? key}) : super(key: key);

  @override
  _MySettingsWidgetState createState() => _MySettingsWidgetState();
}

class _MySettingsWidgetState extends State<MySettingsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool speedUnit = false;
  bool receiveNotifications = false;
  String email = "";
  String password = "";
  String confirmPassword = "";
  String selectedLanguage = "";
  String fullName = "";
  List<String> languages = <String>[
    'English',
    'French',
  ];
  @override
  void initState() {
    super.initState();
    getUserDataField(currentUser!.uid);
  }

  Future<void> updateUser(userId, field, value) {
    return usersRef
        .doc(userId)
        .update({field: value})
        .then((value) => print("User Updated"))
        .catchError((error) => print("Failed to update user: $error"));
  }

  getUserDataField(userId) async {
    await usersRef.doc(userId).get().then((DocumentSnapshot doc) {
      setState(() {
        fullName = doc["FullName"].toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(8.0),
                    color: Theme.of(context).primaryColor,
                    child: ListTile(
                      onTap: () {
                        print("Fullname: " + fullName);
                        showNamePopup();
                      },
                      title: Text(
                        '$fullName',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          'https://picsum.photos/seed/867/600',
                        ),
                      ),
                      trailing: Icon(
                        Icons.edit,
                        color: Colors.white,
                      ),
                    )),
                const SizedBox(height: 10.0),
                Card(
                  elevation: 8,
                  margin: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: Icon(
                          Icons.lock_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text("Change Password"),
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
                        title: Text("Change E-mail"),
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
                        title: Text("Change Language"),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          showLanguagePopup();
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text("Notification Settings",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor)),
                Container(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Receive notifications",
                            style: TextStyle(
                              fontSize: 16.5,
                            )),
                        FlutterSwitch(
                          width: 100.0,
                          height: 35.0,
                          valueFontSize: 18.0,
                          toggleSize: 45.0,
                          value: receiveNotifications,
                          borderRadius: 30.0,
                          padding: 8.0,
                          inactiveColor: Theme.of(context).primaryColor,
                          activeColor: Theme.of(context).primaryColor,
                          activeText: "Yes",
                          inactiveText: "No",
                          showOnOff: true,
                          onToggle: (val) {
                            setState(() {
                              receiveNotifications = val;
                            });
                          },
                        ),
                      ]),
                  margin: const EdgeInsets.only(bottom: 10),
                ),
                const SizedBox(height: 10),
                Text("Speed Settings",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor)),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Speed Unit",
                          style: TextStyle(
                            fontSize: 16.5,
                          )),
                      FlutterSwitch(
                        width: 100.0,
                        height: 35.0,
                        valueFontSize: 18.0,
                        toggleSize: 45.0,
                        value: speedUnit,
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
                          });
                        },
                      ),
                    ]),
                TextButton.icon(
                  onPressed: () {
                    auth.signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => LoginSignup(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: Icon(Icons.logout, size: 18),
                  label: Text("LOG OUT ASBA"),
                )
              ],
            )));
  }

  Container divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      height: 1.0,
      color: Colors.grey,
    );
  }

  Future<void> showPasswordPopup() async {
    await NAlertDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text("Changing Password"),
      content: Container(
        height: 115,
        child: Column(
          children: [
            Text("New password must be atleast 8 characters"),
            TextField(
              decoration: InputDecoration(
                  border: new UnderlineInputBorder(
                      borderSide: new BorderSide(
                          color: Theme.of(context).primaryColor)),
                  hintText: 'Password'),
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
                  hintText: 'Confirm password'),
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
            child: Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
            }),
        FlatButton(
            child: Text("Confirm"),
            onPressed: () {
              checkPassword();
            }),
      ],
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  Future<void> showEmailPopup() async {
    await NAlertDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text("Changing Email"),
      content: Container(
        height: 70,
        child: Column(
          children: [
            Text("Enter the new email you want to add !"),
            TextField(
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
            child: Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
            }),
        FlatButton(
            child: Text("Confirm"),
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
                child: Text(selectedLanguage, overflow: TextOverflow.ellipsis)),
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
      title: Text("Changing Language"),
      content: Container(
        height: 80,
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: Text("Choose the Language you want !")),
            MenuButton<String>(
              child: normalChildButton,
              items: languages,
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
                  Navigator.pop(context);
                });
              },
            )
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
            }),
      ],
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  Future<void> showNamePopup() async {
    await NAlertDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text("Changing Name"),
      content: Container(
        height: 70,
        child: Column(
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [Text("Enter your name !")]),
            TextFormField(
                initialValue: fullName,
                decoration: InputDecoration(
                    border: new UnderlineInputBorder(
                        borderSide: new BorderSide(
                            color: Theme.of(context).primaryColor)),
                    hintText: 'Name'),
                onChanged: (value) {
                  fullName = value;
                }),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
            }),
        FlatButton(
            child: Text("Confirm"),
            onPressed: () {
              checkName();
            }),
      ],
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  void checkName() {
    if (fullName.length < 3) {
      Fluttertoast.showToast(
          msg: "Name too short !",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).errorColor);
    } else {
      Fluttertoast.showToast(
          msg: "Name changed successfully !",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).primaryColor);
      updateUser(currentUser!.uid, "FullName", fullName);
      Navigator.pop(context);
    }
  }

  void checkPassword() {
    if (confirmPassword == password && password.length >= 8) {
      Fluttertoast.showToast(
          msg: "Password changed successfully !",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).primaryColor);
      Navigator.pop(context);
    } else if (confirmPassword != password && password.length >= 8) {
      Fluttertoast.showToast(
          msg: "Passwords don't match !",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).errorColor);
    } else if (confirmPassword == password && password.length < 8) {
      Fluttertoast.showToast(
          msg: "Password too short !",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).errorColor);
    } else {
      Fluttertoast.showToast(
          msg: "Verify your password !",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).errorColor);
    }
  }

  void checkEmail() {
    bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
    if (emailValid) {
      Fluttertoast.showToast(
          msg: "Email changed successfully !",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).primaryColor);
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
          msg: "Verify your email !",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).errorColor);
    }
  }
}
