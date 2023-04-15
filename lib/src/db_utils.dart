import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqlutter/src/table.dart';

class DBUtils {
  static Database? _db;
  static List<Table> tables = [];

  static Future<Database> get db async {
    return _db ?? await initDB();
  }

  static Future<Database> initDB() async {
    if (kIsWeb) {
      // Change default factory on the web
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _db = await openDatabase('local.db');
    await createTables();

    return _db!;
  }

  static Future<void> createTables() async {
    Database db = await DBUtils.db;
    for (Table table in tables) {
      await table.createTable(db);
    }
  }
}
