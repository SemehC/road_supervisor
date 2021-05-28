import 'dart:convert';
import 'dart:io';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:road_supervisor/models/database_manager.dart';
import 'package:road_supervisor/models/db_polyline_item.dart';

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
    var status = await Permission.manageExternalStorage.status;

    if (status.isDenied) {
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

    final folderName = "road_supervisor";
    final path = Directory("storage/emulated/0/$folderName");
    if (!(await path.exists())) {
      await path.create();
    }

    Map<String, dynamic> el = new Map();

    final File file = File('${path.path}/road_scan${id + 1}.json');
    DbPolyline pt = DbPolyline(fileLocation: file.path);
    DatabaseManager.insertToDatabase(pt);
    int count = 0;
    String finalString = "{";
    pts.forEach((element) {
      finalString +=
          "$count : { 'lat' : '${element.lat}','long' : '${element.long}','type' : '${element.type}' } ";
      count++;
    });
    finalString += "}";
    file.writeAsString(finalString);
  }
}
