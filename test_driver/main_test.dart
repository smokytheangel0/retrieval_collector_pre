//@Timeout(const Duration(seconds: 60))
import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_driver_fast_restart/flutter_driver_extensions.dart';
import 'package:test/test.dart';
import 'dart:io';

var TIMEOUT = Timeout(Duration(seconds: 120));
var SEQUENTIAL = true;
var DEBUG = true;

void main() {
  group("", () {
    FlutterDriver driver;
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        await reset(driver);
        driver.close();
      }
    });

    group("new record", () {
      test("rejects no fields completed", () async {
        await reset(driver);

        await go_to_new_record_from_home(driver);
        await set_up_new_record_fields([], driver);

        await expect_tap("done_button", driver);
        await assert_text(
            'please enter any consistent name for the record', driver);
      }, timeout: TIMEOUT);
    });

    group("new record", () {
      test("rejects only name completed", () async {
        await reset(driver);

        await go_to_new_record_from_home(driver);
        await set_up_new_record_fields(["name"], driver);

        await expect_tap("done_button", driver);
        await assert_text("enter time", driver);
      }, timeout: TIMEOUT);
    });

    group("new record", () {
      test("rejects only seconds completed", () async {
        await reset(driver);

        await go_to_new_record_from_home(driver);
        await set_up_new_record_fields(["seconds"], driver);

        await expect_tap("done_button", driver);
        await assert_text(
            "please enter any consistent name for the record", driver);
      }, timeout: TIMEOUT);
    });

    group("new record", () {
      test("rejects only locations and time completed", () async {
        //location buttons will not trigger if seconds not set
        //see test 'start button rejects no seconds'
        await reset(driver);

        await go_to_new_record_from_home(driver);
        await set_up_new_record_fields(["locations", "seconds"], driver);

        await expect_tap("done_button", driver);
        await assert_text(
            "please enter any consistent name for the record", driver);
      }, timeout: TIMEOUT);
    });

    group("new record", () {
      test("rejects alpha in seconds field", () async {
        await reset(driver);

        await go_to_new_record_from_home(driver);
        await set_up_new_record_fields(["name"], driver);

        await expect_tap("second_field", driver);
        await enter_text("abc", driver);

        await expect_tap("done_button", driver);
        await assert_text("numbers only", driver);
      }, timeout: TIMEOUT);
    });

    group("new record", () {
      test("rejects alpha in minutes field", () async {
        await reset(driver);

        await go_to_new_record_from_home(driver);
        await set_up_new_record_fields(["name", "seconds"], driver);

        await expect_tap("minutes_field", driver);
        await assert_text("numbers only", driver);
      }, timeout: TIMEOUT);
    });

    group("new record", () {
      test("accepts all fields complete, and saves record", () async {
        await reset(driver);

        await go_to_new_record_from_home(driver);
        await set_up_new_record_fields(
            ["name", "seconds", "locations"], driver);

        await expect_tap("done_button", driver);
        await assert_text("tester", driver);
      }, timeout: TIMEOUT);
    });

    group("new record", () {
      test("start button rejects no seconds", () async {
        await reset(driver);

        await go_to_new_record_from_home(driver);

        await expect_tap("start_button", driver);
        await assert_text("enter time", driver);
      }, timeout: TIMEOUT);
    });

    group("new record", () {
      test("start button notifies when already set", () async {
        await reset(driver);

        await go_to_new_record_from_home(driver);

        await expect_tap("seconds_field", driver);
        await enter_text("50", driver);
        await expect_tap("start_button", driver);
        await wait_for_text("please travel to the end location", driver);
        await expect_tap("start_button", driver);
        await assert_text("you've already started", driver);
      }, timeout: TIMEOUT);
    });

    group("new record", () {
      test("end button notifies when start is not set", () async {
        await reset(driver);

        await go_to_new_record_from_home(driver);

        await expect_tap("end_button", driver);
        await assert_text("you must set a start location first", driver);
      }, timeout: TIMEOUT);
    });

    group("new record", () {
      test("auto timer stops when end button is pressed", () async {
        await reset(driver);

        await go_to_new_record_from_home(driver);
        await expect_tap("auto_toggle", driver);
        next_waypoint();
        await expect_tap("start_button", driver);
        await wait_for_text("please travel to the end location", driver);
        await wait_for_text("5 seconds", driver);

        await expect_tap("end_button", driver);
        await assert_text("5 seconds", driver);
      }, timeout: TIMEOUT);
    });

    group("new record", () {
      test("auto toggle disables map until locations set", () async {
        await reset(driver);

        await go_to_new_record_from_home(driver);
        await expect_tap("auto_toggle", driver);
        await expect_tap("map_button", driver);
        await assert_text("New Record", driver);
      }, timeout: TIMEOUT);
    });

    group("new record", () {
      test("auto timer increments after start", () async {
        await reset(driver);

        await go_to_new_record_from_home(driver);
        await expect_tap("auto_toggle", driver);
        await expect_tap("start_button", driver);
        await wait_for_text("1 seconds", driver);
        await assert_text("2 seconds", driver);
      }, timeout: TIMEOUT);
    });

    group("new record map", () {
      test("rejects no location set", () async {
        await reset(driver);

        await go_to_new_record_map_from_home(driver);

        await expect_tap("map_done_button", driver);
        await assert_text("one of the locations is not set!", driver);
      }, timeout: TIMEOUT);
    });

    group("new record map", () {
      test("saves new record state", () async {
        await reset(driver);
        await go_to_new_record_from_home(driver);
        await set_up_new_record_fields(
            ["name", "seconds", "locations"], driver);

        await expect_tap("map_button", driver);
        await go_back(driver);

        await assert_text("50", driver);
        await assert_text("tester", driver);

        await expect_tap("start_button", driver);
        if (await toast_shows_text(
            "please wait for accurate location...", driver)) {
          expect(true, false,
              reason:
                  "the location buttons state was not saved after visiting the map");
        }
      }, timeout: TIMEOUT);
    });

    group("new record map", () {
      test("rejects end not set", () async {
        await reset(driver);
        await go_to_new_record_map_from_home(driver);
        await set_up_map_locations(["start"], driver);
        await expect_tap("map_done_button", driver);
        await assert_text("one of the locations is not set!", driver);
      }, timeout: TIMEOUT);
    });

    group("new record map", () {
      test("rejects start not set", () async {
        await reset(driver);
        await go_to_new_record_map_from_home(driver);

        await set_up_map_locations(["end"], driver);

        await expect_tap("map_done_button", driver);
        await assert_text("one of the locations is not set!", driver);
      }, timeout: TIMEOUT);
    });

    group("new record map", () {
      test("notifies on end while start is waiting", () async {
        await reset(driver);
        //this dies before the following even finishes
        await go_to_new_record_map_from_home(driver);
        await expect_tap("map_start_button", driver);
        await expect_tap("map_end_button", driver);
        await assert_text(
            "please tap a location to finish setting the start first", driver);
      }, timeout: TIMEOUT);
    });

    group("new record map", () {
      test("notifies on start while end is waiting", () async {
        await reset(driver);
        await go_to_new_record_map_from_home(driver);
        await expect_tap("map_end_button", driver);
        await expect_tap("map_start_button", driver);
        await assert_text(
            "please tap a location to finish setting the end first", driver);
      }, timeout: TIMEOUT);
    });

    group("new record map", () {
      test("notifies on start after start already set", () async {
        await reset(driver);
        await go_to_new_record_map_from_home(driver);
        await set_up_map_locations(["start"], driver);
        await expect_tap("map_start_button", driver);
        await assert_text("the start location has already been set!", driver);
      }, timeout: TIMEOUT);
    });

    group("new record map", () {
      test("notifies on end after end already set", () async {
        await reset(driver);
        await go_to_new_record_map_from_home(driver);
        await set_up_map_locations(["end"], driver);
        await expect_tap("map_end_button", driver);
        await assert_text("the end location has already been set!", driver);
      }, timeout: TIMEOUT);
    });

    group("new record map", () {
      test("hides buttons after locations set auto", () async {
        await reset(driver);
        await go_to_new_record_from_home(driver);
        await expect_tap("auto_toggle", driver);
        await expect_tap("start_button", driver);
        await wait_for_text("please travel to the end location", driver);
        await expect_tap("end_button", driver);
        await expect_tap("map_button", driver);
        if (await view_shows_text("start", driver)) {
          expect(true, false,
              reason:
                  "start button was not hidden on new record map after locations set in new record");
        }
        if (await view_shows_text("end", driver)) {
          expect(true, false,
              reason:
                  "end button was not hidden on new record map after locations set in new record");
        }
      }, timeout: TIMEOUT);
    });

    group("new record map", () {
      test("hides buttons after locations set estimate", () async {
        await reset(driver);
        await go_to_new_record_from_home(driver);
        await set_up_new_record_fields(
            ["name", "seconds", "locations"], driver);
        await expect_tap("map_button", driver);
        if (await view_shows_text("start", driver)) {
          expect(true, false,
              reason:
                  "start button was not hidden on new record map after locations set in new record");
        }
        if (await view_shows_text("end", driver)) {
          expect(true, false,
              reason:
                  "end button was not hidden on new record map after locations set in new record");
        }
      }, timeout: TIMEOUT);
    });

    group("new record map", () {
      test("still has buttons after setting locations via map", () async {
        await reset(driver);
        await go_to_new_record_map_from_home(driver);
        await set_up_map_locations(["start", "end"], driver);
        await expect_tap("map_done_button", driver);
        await expect_tap("map_button", driver);
        if (!await view_shows_text("start", driver)) {
          expect(true, false,
              reason:
                  "new record map start buttons was hidden after setting locations with map");
        }
        if (!await view_shows_text("end", driver)) {
          expect(true, false,
              reason:
                  "new record map end button was hidden after setting locations with map");
        }
      }, timeout: TIMEOUT);
    });

    group("new record map", () {
      test("accepts complete locations and saves them", () async {
        await reset(driver);
        await go_to_new_record_map_from_home(driver);
        await set_up_map_locations(["start", "end"], driver);
        await expect_tap("map_done_button", driver);
        await assert_text("New Record", driver);
        await expect_tap("start_button", driver);
        if (await toast_shows_text(
            "please wait for accurate location...", driver)) {
          expect(true, false,
              reason:
                  "start was not set after setting both locations in new record map");
        }
        await expect_tap("end_button", driver);
        if (await toast_shows_text(
            "please wait for accurate location...", driver)) {
          expect(true, false,
              reason:
                  "end was not set after setting both locations in new record map");
        }
      }, timeout: TIMEOUT);
    });

    group("direct", () {
      test("notifies when at start location", () async {
        await reset(driver);
        await set_up_direct_record(driver);
        await go_to_direct_from_home(driver);
        next_waypoint();
        await assert_text("please travel to the end location", driver);
      }, timeout: TIMEOUT);
    });

    group("direct", () {
      test("notifies when at end location", () async {
        await reset(driver);
        if (!SEQUENTIAL) {
          await set_up_direct_record(driver);
        }
        await go_to_direct_from_home(driver);
        next_waypoint();
        await toast_shows_text("please travel to the end location", driver);
        next_waypoint();
        await assert_text("detected end location", driver);
      }, timeout: TIMEOUT);
    });

    group("direct", () {
      test("rejects no locations traveled to", () async {
        await reset(driver);
        if (!SEQUENTIAL) {
          await set_up_direct_record(driver);
        }
        await go_to_direct_from_home(driver);
        await expect_tap("done_button", driver);
        await assert_text(
            "must travel to both start and end locations before finishing",
            driver);
      }, timeout: TIMEOUT);
    });

    group("direct", () {
      test("rejects one location traveled to", () async {
        await reset(driver);
        if (!SEQUENTIAL) {
          await set_up_direct_record(driver);
        }
        await go_to_direct_from_home(driver);
        next_waypoint();
        await wait_for_text("please travel to the end location", driver);
        await expect_tap("done_button", driver);
        await assert_text(
            "must travel to both start and end locations before finishing",
            driver);
      }, timeout: TIMEOUT);
    });

    group("direct", () {
      test("rejects end before start", () async {
        await reset(driver);
        if (!SEQUENTIAL) {
          await set_up_direct_record(driver);
        }
        next_waypoint();
        next_waypoint();
        await go_to_direct_from_home(driver);
        if (await toast_shows_text("detected end location", driver)) {
          expect(true, false,
              reason:
                  "the end location was allowed to be set before setting start on direct");
        }
      }, timeout: TIMEOUT);
    });

    group("direct", () {
      test("does not show start set, until at start location", () async {
        await reset(driver);
        if (!SEQUENTIAL) {
          await set_up_direct_record(driver);
        }
        await go_to_direct_from_home(driver);
        if (await toast_shows_text(
            "please travel to the end location", driver)) {
          expect(true, false,
              reason: "the start was set before arriving at start location");
        } else {
          next_waypoint();
          await assert_text("please travel to the end location", driver);
        }
      }, timeout: TIMEOUT);
    });

    group("direct", () {
      test("accepts both locations set", () async {
        await reset(driver);
        if (!SEQUENTIAL) {
          await set_up_direct_record(driver);
        }
        await go_to_direct_from_home(driver);
        next_waypoint();
        await wait_for_text("please travel to the end location", driver);
        next_waypoint();
        await wait_for_text("detected end location", driver);
        await expect_tap("done_button", driver);
        await assert_text("direct_test", driver);
        await expect_tap("tile_1", driver);
        await assert_text("Review", driver);
      }, timeout: TIMEOUT);
    });

    group("direct_map", () {
      test("saves state and passes it back to direct", () async {
        await reset(driver);
        await set_up_direct_record(driver);
        await go_to_direct_from_home(driver);
        next_waypoint();
        await wait_for_text("please travel to the end location", driver);
        next_waypoint();
        await wait_for_text("detected end location", driver);
        var seconds_text_before =
            await driver.getText(find.byValueKey("timer_text"));
        var seconds_before = int.parse(seconds_text_before.split(" ")[0]);
        await expect_tap("map_button", driver);
        await expect_tap("map_done_button", driver);

        var seconds_text_after =
            await driver.getText(find.byValueKey("timer_text"));
        var seconds_after = int.parse(seconds_text_after.split(" ")[0]);
        expect(seconds_after == seconds_before, true,
            reason: "the seconds were reset after visiting direct map");
        next_waypoint();
        next_waypoint();
        if (await toast_shows_text(
            "please travel to the end location", driver)) {
          expect(true, false,
              reason: "direct map did not save the state of the direct fields");
        }
      }, timeout: TIMEOUT);
    });

    group("direct_map", () {
      test("seconds increment while using map", () async {
        await reset(driver);
        await set_up_direct_record(driver);
        await go_to_direct_from_home(driver);
        next_waypoint();
        await wait_for_text("please travel to the end location", driver);
        var seconds_text_before =
            await driver.getText(find.byValueKey("timer_text"));
        var seconds_before = int.parse(seconds_text_before.split(" ")[0]);
        await expect_tap("map_button", driver);
        await expect_tap("map_done_button", driver);

        var seconds_text_after =
            await driver.getText(find.byValueKey("timer_text"));
        var seconds_after = int.parse(seconds_text_after.split(" ")[0]);
        expect(seconds_after > seconds_before, true,
            reason: "the seconds did not increment while using direct map");
      }, timeout: TIMEOUT);
    });

    //groups:
    //
    //    new record:
    //      AUTO!
    //        //timer stops as soon as end is pressed, not when the location has been saved
    //        //map button disables after toggle
    //        //map buttons disable after transit
    //         //timer counts while in transit
    //      name too long
    //      details too long
    //      seconds rejects numbers
    //      minutes rejects numbers (can enter with driver, not restricted to numpad)
    //      //map is disabled while in transit
    //      //map buttons are disabled after transit
    //    new record map:
    //      /accepts completed locations
    //      //still has buttons after done setting map locations
    //      //has no buttons after locations set in new record both auto and detective/direct combo
    //    direct map:
    //      //map saves timer state, and timer is greater than before
    //    review:
    //      data displayed as entered
    //
    //
  });
}

//nav functions (6)
Future<void> set_up_new_record_fields(
    List<String> complete, FlutterDriver driver) async {
  await assert_text("New Record", driver);
  if (complete.isNotEmpty) {
    if (complete.contains("name")) {
      if (DEBUG) {}
      if (DEBUG) {
        print(
            "because we are setting up 'name', we will check if it is clear and enter it");
      }

      if (!await view_shows_text("tester", driver)) {
        await expect_tap("name_field", driver);
        await enter_text("tester", driver);
      }
    } else {
      if (DEBUG) {
        print(
            "because we are not setting up 'name' we will check that it is clear or clear it");
      }

      if (await view_shows_text("tester", driver)) {
        await expect_tap("name_field", driver);
        await enter_text("", driver);
      }
    }
    if (complete.contains("locations")) {
      if (DEBUG) {
        print(
            "because we are setting up 'locations', we will check if they are clear and enter them");
      }
      next_waypoint();
      //location buttons will not trigger if seconds not set
      //see test 'start button rejects no seconds'
      await expect_tap("seconds_field", driver);
      await enter_text("50", driver);

      await expect_tap("start_button", driver);
      if (await toast_shows_text(
          "please wait for accurate location...", driver)) {
        await toast_shows_text("please travel to the end location", driver);
        next_waypoint();
        await expect_tap("end_button", driver);
        await wait_for_text("end location set", driver);
        next_waypoint();
      }
    }
    if (complete.contains("seconds")) {
      if (DEBUG) {
        print(
            "because we are setting up 'seconds', we will check if they are clear and enter them");
      }

      if (!await view_shows_text("50", driver)) {
        await expect_tap("seconds_field", driver);
        await enter_text("50", driver);
      }
    } else {
      if (DEBUG) {
        print(
            "because we are not setting up 'seconds', we will check that they are clear or clear them");
      }

      if (await view_shows_text("50", driver)) {
        await expect_tap("seconds_field", driver);
        await enter_text("", driver);
      }
    }
  } else {
    //going to leave this unpopulated as at least one arg
    //will always be given, as this function will not be needed
    //to clear all fields, it will always be run on a fresh page.
  }
}

Future<void> set_up_map_locations(
    List<String> complete, FlutterDriver driver) async {
  await assert_text("Location Selector", driver);
  await expect_tap("delete_button", driver);
  await wait_for_text("clear locations?", driver);
  await expect_tap("clear_locations_accept", driver);
  await expect_tap("map_button", driver);
  await assert_text("Location Selector", driver);
  next_waypoint();
  if (complete.isNotEmpty) {
    if (complete.contains("start")) {
      await expect_tap("refresh_button", driver);
      await expect_tap("map_start_button", driver);
      await expect_tap("map", driver);
      next_waypoint();
    }
    if (complete.contains("end")) {
      await expect_tap("refresh_button", driver);
      await expect_tap("map_end_button", driver);
      await expect_tap("map", driver);
      next_waypoint();
    }
  } else {
    //ignore because its probably the first start
  }
}

Future<void> set_up_direct_record(FlutterDriver driver) async {
  await go_to_new_record_from_home(driver);
  await set_up_new_record_fields(["seconds"], driver);
  await expect_tap("name_field", driver);
  await enter_text("direct_test", driver);
  await expect_tap("map_button", driver);
  await set_up_map_locations(["start", "end"], driver);
  await expect_tap("map_done_button", driver);
  await expect_tap("done_button", driver);
}

Future<void> go_to_direct_from_home(FlutterDriver driver) async {
  await assert_text("Retrieval Collector", driver);
  await assert_text("direct_test", driver);
  if (DEBUG) {
    print("tapping direct_test tile...");
  }
  await driver.tap(find.text("direct_test"));
  if (DEBUG) {
    print("tapped direct_test tile!");
  }
}

Future<void> go_to_new_record_from_home(FlutterDriver driver) async {
  await assert_text("Retrieval Collector", driver);
  await expect_tap("add_button", driver);
}

Future<void> go_to_new_record_map_from_home(FlutterDriver driver) async {
  await assert_text("Retrieval Collector", driver);
  await expect_tap("add_button", driver);
  await expect_tap("map_button", driver);
}

//helper functions (9)
Future<void> enter_text(String text, FlutterDriver driver) async {
  if (text == "") {
    if (DEBUG) {
      print("clearing field...");
    }

    await driver.enterText("");
    if (DEBUG) {
      print("cleared field!");
    }
  } else {
    if (DEBUG) {
      print("entering '$text'...");
    }

    await driver.enterText(text);
    if (DEBUG) {
      print("entered '$text'!");
    }
  }
}

Future<void> expect_tap(String key, FlutterDriver driver) async {
  var widget = find.byValueKey(key);
  //this appears to have made a difference
  //we can just OR it if any more come up

  var should_sleep = key == "map_button" ||
      key == "refresh_button" ||
      key == "map_end_button" ||
      key == "map_start_button" ||
      key == "map" ||
      key == "map_done_button";

  var sleep_duration = Duration(seconds: 2);

  if (should_sleep) {
    sleep(sleep_duration);
  }
  if (DEBUG) {
    print("tapping '$key'...");
  }

  await driver.tap(widget);
  if (DEBUG) {
    print("tapped '$key'!");
  }
  if (should_sleep) {
    sleep(sleep_duration);
  }
}

Future<void> wait_for_text(String text, FlutterDriver driver) async {
  if (DEBUG) {
    print("waiting for '$text'...");
  }

  try {
    await driver.waitFor(find.text(text));
  } catch (e) {
    if (DEBUG) {
      print("did not find '$text'!");
    }
  }
  if (DEBUG) {
    print("found '$text'!");
  }
}

Future<void> assert_text(String text, FlutterDriver driver) async {
  if (DEBUG) {
    print("checking for '$text'...");
  }
  try {
    await driver.getText(find.text(text), timeout: Duration(seconds: 15));
    if (DEBUG) {
      print("found '$text'");
    }
  } catch (e) {
    expect(false, true, reason: "'$text' was never found!!!");
  }
}

Future<bool> view_shows_text(String text, FlutterDriver driver) async {
  if (DEBUG) {
    print("looking for '$text'...");
  }

  try {
    await driver.getText(find.text(text), timeout: Duration(seconds: 2));
  } catch (e) {
    if (DEBUG) {
      print("found no '$text'");
    }

    return false;
  }
  if (DEBUG) {
    print("found '$text'!");
  }

  return true;
}

Future<bool> toast_shows_text(String text, FlutterDriver driver) async {
  if (DEBUG) {
    print("waiting for toast with '$text' on it...");
  }

  try {
    await driver.getText(find.text(text), timeout: Duration(seconds: 15));
  } catch (e) {
    if (DEBUG) {
      print("found no toast with '$text' on it!");
    }
    return false;
  }
  if (DEBUG) {
    print("found toast with '$text' on it!");
  }
  return true;
}

Future<void> go_back(FlutterDriver driver) async {
  if (DEBUG) {
    print("tapping 'back' on appbar...");
  }
  await driver.tap(find.byTooltip("Back"));
  if (DEBUG) {
    print("tapped 'back' on appbar!");
  }
}

void next_waypoint() {
  print("ready for next waypoint");
}

Future<void> reset(FlutterDriver driver) async {
  await driver.restart();
  print("reset waypoints");
}
