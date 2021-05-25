import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

class MySettingsWidget extends StatefulWidget {
  MySettingsWidget({Key? key}) : super(key: key);

  @override
  _MySettingsWidgetState createState() => _MySettingsWidgetState();
}

class _MySettingsWidgetState extends State<MySettingsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool speedUnit = false;
  bool receiveNotifications = false;
  @override
  void initState() {
    super.initState();
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
                        //Open edit profile name
                      },
                      title: Text(
                        "Fehmi Denguir",
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
                          //open change password modal
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
                          //open change E-mail modal
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
                          //open change language modal
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
}
