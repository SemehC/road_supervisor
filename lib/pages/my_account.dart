import 'dart:io';

import 'package:colours/colours.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:ndialog/ndialog.dart';
import 'package:road_supervisor/generated/codegen_loader.g.dart';
import 'package:road_supervisor/models/database_manager.dart';
import 'package:road_supervisor/models/db_polyline_item.dart';
import 'package:road_supervisor/models/polyline_point.dart';
import 'package:road_supervisor/models/user_manager.dart';
import 'package:road_supervisor/pages/scan_item_page.dart';

import '../main.dart';

class MyAccoutWidget extends StatefulWidget {
  MyAccoutWidget({Key? key}) : super(key: key);

  @override
  _MyAccoutWidgetState createState() => _MyAccoutWidgetState();
}

class _MyAccoutWidgetState extends State<MyAccoutWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> databaseItemsWidgets = [];

  bool isDbEmtpy = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      fetchCurrentLocation();
      fetchAllDbItems();
    });
  }

  fetchCurrentLocation() async {
    var locName = await UserManager.fetchCurrentLocation();
    setState(() {
      currentLocation = locName.first.locality;
    });
  }

  buildPageHeader() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(15, 0, 15, 20),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                height: 70,
                alignment: Alignment.topCenter,
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(
                    UserManager.currentUserProfile.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                  Text(
                    currentLocation,
                  )
                ]),
              ),
            )),
            Align(
              alignment: Alignment(0, 1),
              child: Container(
                margin: const EdgeInsets.only(left: 30),
                width: 80,
                height: 80,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: UserManager.getProfileImage(true),
              ),
            )
          ],
        ),
      ),
    );
  }

  handleUpload(DbPolyline pt) async {
    print("Uploading");
    String fileName = pt.fileLocation.split("/").last;
    await PolyLinePoint.uploadFileToCloudStorage(fileName, pt.fileLocation)
        .then((uploaded) {
      // print("Deleting from database");
      DatabaseManager.updateToUploaded(pt);
      // DatabaseManager.removeFromDb(pt);
      fetchAllDbItems();
    });
  }

  dbItemOptions(DbPolyline pt) async {
    await NDialog(
      title: Text(LocaleKeys.Settings),
      content: Text("this would delete this scan locally"),
      actions: [
        TextButton.icon(
          onPressed: () => {
            handleUpload(pt),
            Navigator.pop(context),
          },
          icon: Icon(Icons.upload_file),
          label: Text("Upload"),
        ),
        TextButton.icon(
          onPressed: () => {
            DatabaseManager.removeFromDb(pt),
            fetchAllDbItems(),
            Navigator.pop(context),
          },
          icon: Icon(Icons.delete_forever),
          label: Text("Delete"),
        ),
      ],
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  buildPolyLineItem({required DbPolyline polyItem}) {
    print("Item image location : " + polyItem.imageLocation);
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ScanItemPage(dbItem: polyItem)));
      },
      onLongPress: () {
        dbItemOptions(polyItem);
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 250,
              height: 150,
              child: Image(
                image: FileImage(File(polyItem.imageLocation)),
                fit: BoxFit.cover,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  'Scan N°${polyItem.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                polyItem.uploadStatus
                    ? Icon(Icons.upload, color: Colours.green)
                    : Icon(
                        Icons.upload,
                        color: Colours.red,
                      ),
              ],
            )
          ],
        ),
      ),
    );
  }

  fetchAllDbItems() async {
    List<DbPolyline> dbitems = await DatabaseManager.getAllPolylines();
    databaseItemsWidgets = [];
    dbitems.forEach((element) {
      setState(() {
        databaseItemsWidgets.add(buildPolyLineItem(polyItem: element));
      });
    });
    if (dbitems.length > 0) {
      setState(() {
        isDbEmtpy = false;
      });
    } else {
      setState(() {
        isDbEmtpy = true;
      });
    }
  }

  buildEmptyPage() {
    return LottieBuilder.asset(
      "assets/lottie/empty_spider.json",
      animate: true,
      repeat: true,
      width: MediaQuery.of(context).size.width,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Color(0xFFE6E6E6),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          buildPageHeader(),
          Divider(
            thickness: 1,
            color: Color(0xFF5B5B5B),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  isDbEmtpy ? buildEmptyPage() : Text(""),
                  ...databaseItemsWidgets,
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
