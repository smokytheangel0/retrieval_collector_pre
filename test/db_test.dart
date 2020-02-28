import 'package:james_data/model.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  reset_database();

  test("detective removes entry and inserts in history", () async {
    var database = open_database();
    var detective = new Detective(using: database);

    var first_input = new DetectiveData(
        retrieval_time: 15,
        start_spot: "47.596534, -122.622991",
        end_spot: "47.608274, -122.621855",
        user: "Self",
        details: "test",
        timestamp: DateTime.now().millisecondsSinceEpoch,
        collection_method: "self");
    await detective.insert(first_input);

    var second_input = new DetectiveData(
        retrieval_time: 30,
        start_spot: "47.596534, -122.622991",
        end_spot: "47.608274, -122.621855",
        user: "Self",
        details: "test",
        timestamp: DateTime.now().millisecondsSinceEpoch,
        collection_method: "self");
    await detective.insert(second_input);

    var entry_list = await detective.entry_list();
    assert(entry_list.isNotEmpty,
        "detective insert() did not work or entry_list() did not work");
    expect(entry_list[0]["retrieval_time"], 30,
        reason: "detective had an incorrect retrieval time");

    var history_list = await detective.history_list();
    assert(history_list.isNotEmpty,
        "detective_history insert() did not work or detective history_list did not work");
    expect(history_list[0]["retrieval_time"], 15,
        reason: "detective_history had an incorrect retrieval time");

    detective.shutdown();
    reset_database();
  });

  test("direct removes entry and inserts in history", () async {
    var database = open_database();
    var direct = new Direct(using: database);

    var first_input = new DirectData(
        start_spot: "47.596534, -122.622991",
        end_spot: "47.608274, -122.621855",
        retrieval_time: 15,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    await direct.insert(first_input);

    var second_input = new DirectData(
        start_spot: "47.596534, -122.622991",
        end_spot: "47.608274, -122.621855",
        retrieval_time: 30,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    await direct.insert(second_input);

    var entry_list = await direct.entry_list();
    assert(entry_list.isNotEmpty,
        "direct insert() did not work or entry_list() did not work");
    expect(entry_list[0]["retrieval_time"], 30,
        reason: "direct had an incorrect retrieval time");

    var history_list = await direct.history_list();
    assert(history_list.isNotEmpty,
        "direct_history insert() did not work or direct history() did not work");
    expect(history_list[0]["retrieval_time"], 15,
        reason: "direct_history had an incorrect retrieval time");

    direct.shutdown();
    reset_database();
  });
}
