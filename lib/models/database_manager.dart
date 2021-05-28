import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'db_polyline_item.dart';

class DatabaseManager {
  static late Database database;
  static initializeDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'doggie_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE polylines(id INTEGER PRIMARY KEY, fileLocation TEXT, uploadStatus BOOL)',
        );
      },
      version: 1,
    );
  }

  static insertToDatabase(DbPolyline pt) async {
    await database.insert(
      'polylines',
      pt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
