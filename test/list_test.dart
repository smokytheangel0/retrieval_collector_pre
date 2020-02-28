//this is where we set up a db
//pump it full of examples
//and then run get_list()
//and see if the output is correct
import 'package:james_data/model.dart';
import 'package:james_data/main_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:math';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  reset_database();
  test("get_list correctly sorts matches and non matches", () async {
    var database = open_database();
    var detective = await Detective(using: database);
    var direct = await Direct(using: database);

    var start_coord_x = 47.596534;
    var start_coord_y = -122.622991;

    var end_coord_x = 47.608274;
    var end_coord_y = -122.621855;
    var number_of_matches = 0;

    //set to 1001 after optimizing alg,
    //this times out in 30 seconds with naive impl
    for (int i = 1; i < 200; i++) {
      var random = new Random();
      var rand_int = random.nextInt(2);
      start_coord_x++;
      start_coord_y++;
      end_coord_x++;
      end_coord_y++;

      var detective_input = new DetectiveData(
        //this is the limit for each line of the details on phone
        //testahitehodasabebitetonogohotohotonenehodetoned 48 chars
        //this is the limit for the user line
        //testerahitehodasabebitetonogohotohotoneneh 42 chars
        details: "this test worked excellently",
        user: "interviewee $i",
        retrieval_time: 5 + i,
        end_spot: "$end_coord_x, $end_coord_y",
        start_spot: "$start_coord_x, $start_coord_y",
        timestamp: DateTime.now().millisecondsSinceEpoch,
        collection_method: "self"
      );
      await detective.insert(detective_input);

      if (rand_int == 1) {
        var direct_input = new DirectData(
          start_spot: "$start_coord_x, $start_coord_y",
          end_spot: "$end_coord_x, $end_coord_y",
          retrieval_time: 1 + i,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        await direct.insert(direct_input);
        number_of_matches++;
      }
    }
    //this builder mess is neccesary, because get_list
    //needs the app context in order to handle routing when tapped
    Builder(
      builder: (BuildContext context) {
        Timeline.startSync("get_list");
        get_list(context).then((widget_list) {
          Timeline.finishSync();
          var num_of_0E86C = 0;
          for (var widget in widget_list) {
            if (widget.trailing.toString() == "Icon(IconData(U+0E86C))") {
              num_of_0E86C++;
            }
          }
          expect(num_of_0E86C, number_of_matches,
              reason:
                  "the number of checks did not match the number of matches in the dataset");
        });
        // The builder function must return a widget.
        return Placeholder();
      },
    );

    //U+0E5C9 is a non match (cancel)
    //U+0E86C is a match (check)
    reset_database();

  });
}
