import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlutter/sqlutter.dart';
import 'package:sqlutter/src/storage.dart';

abstract class Table {
  Table();

  abstract final String tableName;

  int id = 0;
  DateTime dateCreated = DateTime.now().toUtc();
  DateTime dateModified = DateTime.now().toUtc();

  abstract final List<Storage> columns;

  bool trackDateCreated = true;
  bool trackDateModified = true;
  bool continueOnError = kReleaseMode;

  Future<void> createTable(
    Database? db,
  ) async {
    db = db ?? await DBUtils.db;
    String sql;

    sql = """
    CREATE TABLE IF NOT EXISTS $tableName (
      ${createColumnSQL()}
    )
    """;

    try {
      await db.execute(sql);
    } on DatabaseException catch (e) {
      String eString = e.toString();
      if (eString.contains('database is locked') ||
          eString.contains('unable to open database file')) {
        await Future.delayed(const Duration(milliseconds: 50));
        await createTable(db);
      } else {
        rethrow;
      }
    }
  }

  String createColumnSQL() {
    String sql = 'id INTEGER PRIMARY KEY NOT NULL,\n';
    for (Storage column in columns) {
      sql += '${column.name} ${column.storageName}';
      if (column.nullable) sql += ' NOT NULL ';
      sql += ',\n';
    }
    if (trackDateCreated) sql += 'date_created DATETIME NOT NULL,\n';
    if (trackDateModified) sql += 'date_modified DATETIME NOT NULL,\n';
    sql = sql.replaceFirst(',', '', sql.length - 2);
    return sql;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      for (Storage column in columns) column.name: column.sqlValue,
      if (trackDateCreated) 'date_created': dateCreated.toString(),
      if (trackDateModified) 'date_modified': dateModified.toString(),
    };
  }

  void fromMap(Map<String, dynamic> map) {
    for (Storage column in columns) {
      column.sqlValue = map[column.name];
    }
  }

  Future<Iterable<Map<String, dynamic>>> select({
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      return await (await DBUtils.db).query(
        tableName,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
      );
    } on DatabaseException catch (e) {
      String eString = e.toString();
      if (eString.contains('database is locked') ||
          eString.contains('unable to open database file')) {
        await Future.delayed(const Duration(milliseconds: 50));
        return await select(
          columns: columns,
          where: where,
          whereArgs: whereArgs,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> insert(
    Iterable<dynamic> inserts, {
    bool replaceOnError = true,
  }) async {
    if (inserts.isNotEmpty) {
      ConflictAlgorithm? conflictAlgorithm;
      conflictAlgorithm = replaceOnError ? ConflictAlgorithm.replace : null;

      try {
        await (await DBUtils.db).transaction((txn) async {
          Batch batch = txn.batch();
          for (Map<String, dynamic> insert in inserts) {
            batch.insert(
              tableName,
              insert,
              conflictAlgorithm: conflictAlgorithm,
            );
          }
          await batch.commit(
            continueOnError: continueOnError,
            noResult: true,
          );
        });
      } on DatabaseException catch (e) {
        String eString = e.toString();
        if (eString.contains('database is locked') ||
            eString.contains('unable to open database file')) {
          await Future.delayed(const Duration(milliseconds: 50));
          await insert(inserts, replaceOnError: replaceOnError);
        } else {
          rethrow;
        }
      }
    }
  }

  Future<void> update(
    Iterable<dynamic> updates, {
    String? primaryKey,
  }) async {
    if (updates.isNotEmpty) {
      try {
        await (await DBUtils.db).transaction((txn) async {
          Batch batch = txn.batch();
          for (Map<String, dynamic> update in updates) {
            batch.update(
              tableName,
              update,
              where: "${primaryKey ?? 'id'} = ?",
              whereArgs: [update[primaryKey ?? 'id']],
            );
          }
          await batch.commit(
            continueOnError: continueOnError,
            noResult: true,
          );
        });
      } on DatabaseException catch (e) {
        String eString = e.toString();
        if (eString.contains('database is locked') ||
            eString.contains('unable to open database file')) {
          await Future.delayed(const Duration(milliseconds: 50));
          await update(updates, primaryKey: primaryKey);
        } else {
          rethrow;
        }
      }
    }
  }

  Future<void> delete(
    Iterable<int> deletions, {
    String? primaryKey,
  }) async {
    if (deletions.isNotEmpty) {
      try {
        await (await DBUtils.db).transaction((txn) async {
          Batch batch = txn.batch();
          for (int delete in deletions) {
            batch.delete(
              tableName,
              where: "${primaryKey ?? 'id'} = ?",
              whereArgs: [delete],
            );
          }
          await batch.commit(
            continueOnError: continueOnError,
            noResult: true,
          );
        });
      } on DatabaseException catch (e) {
        String eString = e.toString();
        if (eString.contains('database is locked') ||
            eString.toString().contains('unable to open database file')) {
          await Future.delayed(const Duration(milliseconds: 50));
          await delete(deletions, primaryKey: primaryKey);
        } else {
          rethrow;
        }
      }
    }
  }

  Future<void> deleteSelf() async {
    await delete([id]);
  }

  Future<void> deleteAll() async {
    try {
      await (await DBUtils.db).transaction((txn) async {
        await txn.delete(tableName);
      });
    } on DatabaseException catch (e) {
      String eString = e.toString();
      if (eString.contains('database is locked') ||
          eString.contains('unable to open database file')) {
        await Future.delayed(const Duration(milliseconds: 50));
        await deleteAll();
      } else {
        rethrow;
      }
    }
  }

  /// Loads class from db using primary key [id].
  Future<void> load(int id) async {
    Iterable<Map<String, dynamic>> results = await select(
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      fromMap(results.first);
    } else {
      throw DBEmptyResultException("No $tableName with that id, $id");
    }
  }

  /// Resets info by reloading from db.
  Future<void> reset() async {
    await load(id);
  }

  void dispose() {
    for (Storage column in columns) {
      column.dispose();
    }
  }
}
