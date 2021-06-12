import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:road_supervisor/models/database_manager.dart';
import 'package:road_supervisor/models/db_polyline_item.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import 'user_manager.dart';

class PolyLinePoint {
  final num lat;
  final num long;
  /*
  0=> good
  1=> avg
  2=>bad
  */
  final num type;

  PolyLinePoint({
    required this.lat,
    required this.long,
    required this.type,
  });

  static Future<void> savePolylinePointsToLocal(List<PolyLinePoint> pts) async {
    var status = await Permission.storage.status;

    if (status.isDenied) {
      await Permission.storage.request();
      if (await Permission.manageExternalStorage.request().isDenied) {
        Fluttertoast.showToast(msg: "Permission not accepted");
        return;
      }
    }

    if (status.isPermanentlyDenied) {
      Fluttertoast.showToast(msg: "Please change permission in app settings");
      return;
    }

    int id = (await DatabaseManager.getAllPolylines()).length;

    final path = await getStorageDir();

    final File file = File('${path.path}/road_scan${id + 1}.json');
    DbPolyline pt = DbPolyline(
        id: id + 1,
        fileLocation: file.path,
        imageLocation: "${path.path}/road_scan${id + 1}.jpg");
    DatabaseManager.insertToDatabase(pt);
    int count = 0;
    String finalString = "{";
    pts.forEach((element) {
      finalString +=
          '"$count":{ "lat" : "${element.lat}","long" : "${element.long}","type" : "${element.type}" },';
      count++;
    });
    finalString += "}";
    file.writeAsString(finalString);
    print("Done saving file ");
  }

  static downloadCloudData() async {
    var httpClient = new HttpClient();
    final path = await getStorageDir();
    var l = await DatabaseManager.getAllDownloadedPolylines();
    int id = l.length;
    var qs = await scansRef.get();
    for (int i = 0; i < qs.size; i++) {
      var currDoc = qs.docs[i];
      if (!await DatabaseManager.checkIfExistsInCloudDb(currDoc.id)) {
        var url = currDoc["FileLocation"];
        var request = await httpClient.getUrl(Uri.parse(url));
        var response = await request.close();
        var bytes = await consolidateHttpClientResponseBytes(response);
        File file = new File('${path.path}/${currDoc.id}.json');
        await file.writeAsBytes(bytes);
        id++;
        DbPolyline pt =
            DbPolyline(id: id, fileLocation: file.path, onlineId: currDoc.id);
        DatabaseManager.insertToCloudDatabase(pt);
        print("Added new file to local db");
      } else {
        print("Already present in db");
      }
    }
  }

  static Future<Set<Polyline>> handleJsonFile(
      String fileLocation, String prefix) async {
    Set<Polyline> _polyline = {};
    int id = 0;
    LatLng? prevPos = null;
    List<LatLng> currentPoints = [];
    int currRoadType = -1;
    File f = File(fileLocation);
    String s = await f.readAsString();
    var cl = s.substring(0, s.length - 2);
    cl += "}";
    print(cl);
    var js = json.decode(cl) as Map<String, dynamic>;
    print("File length : ${js.length}");
    js.forEach((key, value) {
      LatLng currPos =
          LatLng(double.parse(value['lat']), double.parse(value['long']));

      int roadTp = int.parse(value['type']);
      print("Roadtp : $roadTp");
      if (roadTp == 0) {
        print("Added type 0");
        if (currRoadType != 0) {
          currentPoints = [];
          if (prevPos != null) {
            currentPoints.add(prevPos!);
          }
          _polyline.add(Polyline(
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
            polylineId: PolylineId("$prefix${id + 1}"),
            visible: true,
            points: currentPoints,
            color: Colors.red,
          ));
          //_addNewPolyline(type: 0, preFix: prefix);
          currRoadType = 0;
          id++;
        }
      }
      if (roadTp == 1) {
        if (currRoadType != 1) {
          currentPoints = [];
          if (prevPos != null) {
            currentPoints.add(prevPos!);
          }
          _polyline.add(Polyline(
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
            polylineId: PolylineId("$prefix${id + 1}"),
            visible: true,
            points: currentPoints,
            color: Colors.orange,
          ));
          id++;
          //_addNewPolyline(type: 1, preFix: prefix);
          currRoadType = 1;
        }
      }

      if (roadTp == 2) {
        print("Road type 2 condition ");
        if (currRoadType != 2) {
          currentPoints = [];
          if (prevPos != null) {
            currentPoints.add(prevPos!);
          }
          print("Added a line type 2 ");
          _polyline.add(Polyline(
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
            polylineId: PolylineId("$prefix${id + 1}"),
            visible: true,
            points: currentPoints,
            color: Colors.blue,
          ));
          id++;
          //_addNewPolyline(type: 2, preFix: prefix);
          currRoadType = 2;
        }
      }
      currentPoints.add(currPos);
      prevPos = currPos;
    });
    return _polyline;
  }

  static Future<List<Set<Polyline>>> loadDownloadedPolylines() async {
    List<Set<Polyline>> polyLines = [];
    List<DbPolyline> downloaded =
        await DatabaseManager.getAllDownloadedPolylines();
    print("Downloaded count : ${downloaded.length}");
    for (int i = 0; i < downloaded.length; i++) {
      var poly = await handleJsonFile(downloaded[i].fileLocation, "cloud_$i");

      polyLines.add(poly);
    }
    print("Total polylinesLength : ${polyLines.length}");
    return polyLines;
  }

  static uploadFileToCloudStorage(String fileName, String fileLocation) async {
    String randId = Uuid().v1();
    storageRef
        .child("scans")
        .child("${randId}_$fileName")
        .putFile(File(fileLocation))
        .then((taskSnapShot) async {
      String downUrl = await taskSnapShot.ref.getDownloadURL();
      var locName = await UserManager.fetchCurrentLocation();
      String location = locName.first.coordinates.toString();
      String country = locName.first.countryCode.toLowerCase();
      String locality = locName.first.locality.toLowerCase();
      String adminArea = locName.first.adminArea.toLowerCase();
      await scansRef.doc().set({
        "FileLocation": downUrl,
        "GeoLocation": location,
        "Country": country,
        "Locality": locality,
        "administrativeArea": adminArea,
        "UserId": currentUser!.uid,
        "uploadDate": DateTime.now(),
      }).then((value) {
        print("Uploaded successfully !");
      });
    });
  }

  static savePolylineSnaphotToLocal(Uint8List? u8intListImage) async {
    final path = await getStorageDir();
    int id = (await DatabaseManager.getAllPolylines()).length;
    final File file = File('${path.path}/road_scan$id.jpg');
    file.writeAsBytes(u8intListImage!);
  }

  static Future<Directory> getStorageDir() async {
    final folderName = "road_supervisor";
    final dirPath = await getExternalStorageDirectory();
    final path = Directory("${dirPath!.path}/$folderName");
    if (!(await path.exists())) {
      await path.create();
    }
    return path;
  }
}
