import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'db_polyline_item.dart';

class DatabaseManager {
  static late Database database;
  static initializeDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'road_supervisor.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE polylines(id INTEGER PRIMARY KEY, fileLocation TEXT, uploadStatus BOOL)',
        );
      },
      version: 1,
    );
  }

  static insertToDatabase(DbPolyline pt) async {
    print("Adding to db");
    await database.insert(
      'polylines',
      pt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("Added to db");
  }

  static removeFromDb(DbPolyline pt) async {
    await database.delete("polylines", where: "id = ?", whereArgs: [pt.id]);
  }

  static Future<List<DbPolyline>> getAllPolylines() async {
    final List<Map<String, dynamic>> maps = await database.query('polylines');

    return List.generate(maps.length, (i) {
      return DbPolyline(
        id: maps[i]['id'],
        fileLocation: maps[i]['fileLocation'],
        uploadStatus: maps[i]['uploadStatus'] == 1,
      );
    });
  }
}
