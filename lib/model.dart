import 'dart:async';

import 'package:sqflite/sqflite.dart';

class DirectData {
  String id;
  String start_spot;
  String end_spot;
  int retrieval_time;
  int timestamp;

  DirectData({this.start_spot, this.end_spot, this.retrieval_time, this.timestamp}) {
    this.id = this.start_spot +"; "+ this.end_spot;
  }

  Map<String, dynamic> toMap() {
    return {
      "id": this.id,
      "retrieval_time": this.retrieval_time,
      "timestamp": this.timestamp
    };
  }
}

class DetectiveData {
  String id;
  int retrieval_time;
  String start_spot;
  String end_spot;
  String user;
  String details;
  int timestamp;
  String collection_method;

  DetectiveData({this.retrieval_time, this.start_spot, this.end_spot, this.user, this.details, this.timestamp, this.collection_method}) {
//truncate ID so more similar locations are grouped as duplicates
    this.id = this.start_spot +"; "+ this.end_spot;
  }

  Map<String, dynamic> toMap() {
    return {
      "id": this.id,
      "retrieval_time": this.retrieval_time,
      "start_spot": this.start_spot,
      "end_spot": this.end_spot,
      "user": this.user,
      "details": this.details,
      "timestamp": this.timestamp,
      "collection_method": this.collection_method
    };
  }
}

//this exists because on first connection
//we want to create all the tables at once
//otherwise onCreate will not fire
Future<Database> open_database() async {
  return openDatabase(
      'retrieval_database.db',
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE detective(id TEXT PRIMARY KEY, retrieval_time INTEGER, start_spot TEXT, end_spot TEXT, user TEXT, details TEXT, timestamp INTEGER, collection_method TEXT)",        
        );
        await db.execute(
          "CREATE TABLE detective_history(id TEXT PRIMARY KEY, retrieval_time INTEGER, start_spot TEXT, end_spot TEXT, user TEXT, details TEXT, timestamp INTEGER, collection_method TEXT)",        
        );
        await db.execute(
          "CREATE TABLE direct(id TEXT PRIMARY KEY, retrieval_time INTEGER, timestamp INTEGER)",          
        );
        await db.execute(
          "CREATE TABLE direct_history(id TEXT PRIMARY KEY, retrieval_time INTEGER, timestamp INTERGER)",
        );
    },
      version: 1
    
  );
}

class Detective {
  String id; //= start_spot +"; "+ end spot
  int retrieval_time; //seconds (converted from mm::ss)
  String start_spot;
  String end_spot;
  int timestamp;
  Future<Database> using;
  DetectiveHistory detective_history;

  
  
  Detective({this.using}) {
    this.detective_history = new DetectiveHistory(using: this.using);
  }

  Future<DetectiveData> retrieve(String id) async {
    final Database db = await this.using;
    List<Map<String, dynamic>> results = await db.query('detective', columns: ['*'], where: 'id = ?', whereArgs: [id]);
    return DetectiveData(
      user: results[0]['user'],
      details: results[0]['details'],
      retrieval_time: results[0]['retrieval_time'],
      end_spot: results[0]['end_spot'],
      start_spot: results[0]['start_spot'],
      timestamp: results[0]['timestamp'],
      collection_method: results[0]['collection_method'],
    );
  }

  Future<void> insert(DetectiveData new_fields) async {
    final Database db = await this.using;
//do direct search and flush to history if result here as well, and possibly remove it from direct
    List<Map<String, dynamic>> old_detective_results = await db.query('detective', columns: ['*'], where: 'id = ?', whereArgs: [new_fields.id]);
    List<Map<String, dynamic>> old_direct_results = await db.query('direct', columns: ['*'], where: 'id = ?', whereArgs: [new_fields.id]);

    if (old_detective_results.isNotEmpty) {
      //insert into detective_history, remove from detective
      Map<String, dynamic> old_fields = old_detective_results[0];
      this.detective_history.insert(old_fields);
      int count = await db.rawDelete('DELETE FROM detective WHERE id = ?', [old_fields['id']]);
      assert(count == 1, "an entry was not deleted from detective after insertion in detective history");
    }

    if (old_direct_results.isNotEmpty) {
      var direct = Direct(using: this.using);
      Map<String, dynamic> old_fields = old_direct_results[0];
      direct.direct_history.insert(old_fields);
      int count = await db.rawDelete("DELETE FROM direct WHERE id = ?", [old_fields['id']]);
      assert(count == 1, "an entry was not deleted from direct after insertion into direct history");
    }

    //then perform the insert 
    //if we did this right, rollback should never occur
    await db.insert(
      'detective',
      new_fields.toMap(),
      conflictAlgorithm: ConflictAlgorithm.rollback,
    );
  }
  
  Future<List<Map<String, dynamic>>> entry_list() async {
    final Database db = await this.using;

    List<Map<String, dynamic>> list = await db.query('detective');
    return list;

  }

  Future<List<Map<String, dynamic>>> history_list() async {
    return this.detective_history.entry_list();
  }

  //need to make sure we call this by lifecycle
  //as well as at the end
  Future<void> shutdown() async {
    final Database db = await this.using;
    await db.close();
    if (this.detective_history != null) {
      this.detective_history.shutdown();
    }
  }
}

class DetectiveHistory {

  Future<Database> using;
  
  DetectiveHistory({this.using});

  Future<void> insert(Map<String, dynamic> old_fields) async {
    final Database db = await this.using;

    await db.insert(
      'detective_history',
      old_fields,
      conflictAlgorithm: ConflictAlgorithm.rollback,
    );
  }

  Future<List<Map<String, dynamic>>> entry_list() async {
    final Database db = await this.using;

    List<Map<String, dynamic>> list = await db.query('detective_history');
    return list;

  }

  Future<void> shutdown() async {
    final Database db = await this.using;
    await db.close();
  }
}

class Direct {
  Future<Database> using;
  DirectHistory direct_history;

  Direct({this.using}) {
    this.direct_history = new DirectHistory(using: this.using);
  }

  Future<DirectData> retrieve(String id) async {
    final Database db = await this.using;
    List<Map<String, dynamic>> results = await db.query('direct', columns: ['*'], where: 'id = ?', whereArgs: [id]);
    return DirectData(
      retrieval_time: results[0]['retrieval_time'],
//somehow these come back null in Details.review
//and probably fails in this constructor when
//direct.retrieve is called
      end_spot: results[0]['end_spot'],
      start_spot: results[0]['start_spot'],
      timestamp: results[0]['timestamp'],
    );
  }

  Future<void> insert(DirectData new_fields) async {
    final Database db = await this.using;

    List<Map<String, dynamic>> old_results = await db.query('direct', columns: ['*'], where: 'id = ?', whereArgs: [new_fields.id]);
    if (old_results.isNotEmpty) {
      Map<String, dynamic> old_fields = old_results[0];
      //insert into direct_history, remove from direct
      this.direct_history.insert(old_fields);
      int count = await db.rawDelete('DELETE FROM direct WHERE id = ?', [old_fields['id']]);
      assert(count == 1, "an entry was not deleted from direct after insertion in direct history");
    }

    //then perform the insert 
    //if we did this right, rollback should never occur
    await db.insert(
      'direct',
      new_fields.toMap(),
      conflictAlgorithm: ConflictAlgorithm.rollback,
    );
  }

  Future<List<Map<String, dynamic>>> entry_list() async {
    final Database db = await this.using;

    List<Map<String, dynamic>> list = await db.query('direct');
    return list;

  }
  
  Future<List<Map<String, dynamic>>> history_list() async {
    return this.direct_history.entry_list();
  }
  //need to make sure we call this by lifecycle as well as
  //at the end
  void shutdown() async {

    final Database db = await this.using;
    await db.close();
    
    if (direct_history != null) {
      this.direct_history.shutdown();
    }
  }
}

class DirectHistory {
  Future<Database> using;

  DirectHistory({this.using});

  Future<void> insert(Map<String, dynamic> old_fields) async {
    final Database db = await this.using;

    await db.insert(
      'direct_history',
      old_fields,
      conflictAlgorithm: ConflictAlgorithm.rollback,
    );
  }

  Future<List<Map<String, dynamic>>> entry_list() async {
    final Database db = await this.using;

    List<Map<String, dynamic>> list = await db.query('direct_history');
    return list;

  }

  Future<void> shutdown() async {

    final Database db = await this.using;
    await db.close();
  }
}

void export_csv() {
  //need to be able to export to two csv files in user space or web
  //in lieu of a deleted flag, this should check to make sure each
  //entry has a spot in both detective and direct and if not, discard
}

reset_database() {
  deleteDatabase('retrieval_database.db');
}

//this needs to be a member of detective so it can use the db
bool delete(String id) {
  //this function should only delete detective entries for retry
  //it should only work on detective only entries, and we should probably
  //check that here and return true or false
  
  //check the direct table for matching id
  //if found return false
  //else move the entry in detective to the detective_history
  //and return true

}
