import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'db_polyline_item.dart';

class DatabaseManager {
  static late Database database;

  static initializeDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'road_supervisor.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE generated_polylines(id INTEGER PRIMARY KEY, fileLocation TEXT, uploadStatus BOOL, imageLocation TEXT)',
        );
        await db.execute(
          'CREATE TABLE downloaded_polylines(id INTEGER PRIMARY KEY, fileLocation TEXT, uploadStatus BOOL, imageLocation TEXT, networkId TEXT)',
        );
        return;
      },
      version: 1,
    );
  }

  static checkIfExistsInCloudDb(String docId) async {
    try {
      var res = await database.query('downloaded_polylines',
          where: "networkId = ?", whereArgs: [docId]);

      return res.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static insertToCloudDatabase(DbPolyline pt) async {
    await database.insert(
      'downloaded_polylines',
      pt.toCloudMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<DbPolyline>> getAllDownloadedPolylines() async {
    final List<Map<String, dynamic>> maps =
        await database.query('downloaded_polylines');

    return List.generate(maps.length, (i) {
      return DbPolyline(
        id: maps[i]['id'],
        fileLocation: maps[i]['fileLocation'],
        uploadStatus: maps[i]['uploadStatus'] == 1,
        imageLocation: maps[i]['imageLocation'],
      );
    });
  }

  static insertToDatabase(DbPolyline pt) async {
    await database.insert(
      'generated_polylines',
      pt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static updateToUploaded(DbPolyline pt) async {
    await database.update("generated_polylines", {"uploadStatus": true},
        where: "id = ?", whereArgs: [pt.id]);
  }

  static removeFromDb(DbPolyline pt) async {
    await database
        .delete("generated_polylines", where: "id = ?", whereArgs: [pt.id]);
    File(pt.imageLocation)
        .delete()
        .then((value) => print("Deleted local image"));
    File(pt.fileLocation).delete().then((value) => print("Deleted local scan"));
  }

  static Future<List<DbPolyline>> getAllPolylines() async {
    final List<Map<String, dynamic>> maps =
        await database.query('generated_polylines');

    return List.generate(maps.length, (i) {
      print("Item image location from database : ");
      print(maps[i]['imageLocation']);
      return DbPolyline(
        id: maps[i]['id'],
        fileLocation: maps[i]['fileLocation'],
        uploadStatus: maps[i]['uploadStatus'] == 1,
        imageLocation: maps[i]['imageLocation'],
      );
    });
  }
}
