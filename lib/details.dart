import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:james_data/model.dart';
import 'dart:core';
import 'dart:async';
import 'dart:math';
import 'dart:io';
//this take a true or a false or a null depending on if a record is finished
//or the record needs a direct
//or the record is just starting

//the caller will also send an id which can be used to call into the db
//to do details specific transactions

//this id is null when a new record is created

class DetailsView extends StatefulWidget {
  DetailsView({Key key, this.id, this.match, this.state}) : super(key: key);
  final String id;
  final bool match;
  Map<String, dynamic> state;

  @override
  _DetailsViewState createState() =>
      _DetailsViewState(id: this.id, match: this.match, state: this.state);
}

class _DetailsViewState extends State<DetailsView> {
  final String id;
  final bool match;
  Map<String, dynamic> state;

  final userController = TextEditingController();
  final detailsController = TextEditingController();
  final minutesController = TextEditingController();
  final secondsController = TextEditingController();
  String start;
  String end;
  bool isStartDisabled = false;
  Color startIconColor = Colors.green;
  bool isEndDisabled = false;
  Color endIconColor = Colors.red;
  bool isMapDisabled = false;
  bool isToggleDisabled = false;
  bool waitForLocation = false;
  final _infoKey = GlobalKey<FormState>();
  final _timeKey = GlobalKey<FormState>();
  //true == auto and false == manual
  bool _timeToggle;
  int seconds = 0;
  Details startup;
  Stopwatch timer = null;
  Timer tick = null;
  bool startDone = null;
  bool endDone = null;
  double direct_distance = null;
  Map<String, dynamic> review_map = null;
  double endDistance = 0;
  double startDistance = 0;
  double location_wait = 1.0;
  bool stop_stream = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  _DetailsViewState({this.id, this.match, this.state});

  @override
  void initState() {
    super.initState();
    if (this.id == null) {
      this.startup = Details.initial;
    }
    if (this.match != null) {
      if (this.match == true) {
        this.startup = Details.review;
      } else {
        this.startup = Details.direct;
      }
    }
    //common startup here
    if (this.state != null) {
      if (this.state['start'] != null) {
        this.isStartDisabled = true;
        this.isToggleDisabled = true;

        this.start = this.state['start'];
      }
      if (this.state['end'] != null) {
        this.isEndDisabled = true;
        this.isToggleDisabled = true;
        this.end = this.state['end'];
      }

      this._timeToggle = this.state['time_toggle'];
      this.userController.text = this.state['user'];
      this.detailsController.text = this.state['details'];
      this.minutesController.text = this.state['minutes'];
      this.secondsController.text = this.state['est_seconds'];
      this.seconds = this.state['seconds'];
    } else {
      this._timeToggle = false;
    }
    //split startup below
    if (this.startup == Details.initial) {
    } else if (this.startup == Details.direct) {
      if (this.state != null) {
        if (this.state.containsKey("used_map")) {
          this.timer = this.state['timer'];
          this.direct_distance = this.state['direct_distance'];
          this.startDone = this.state['startDone'];
          this.endDone = this.state['endDone'];
          if (this.startDone != true) {
            this.startIconColor = Colors.deepPurple;
            this.endIconColor = Colors.grey;
          }
          if (this.startDone == true && this.endDone != true) {
            this.endIconColor = Colors.deepPurple;
          }
          this.start = this.state['start'];
          this.end = this.state['end'];
          this.stop_stream = false;
          if (!this.startDone || !this.endDone) {
            if (this.timer != null) {
              this.timer.start();
              this.tick = Timer.periodic(Duration(seconds: 1), (timer) {
                if (this.seconds != this.timer.elapsed.inSeconds) {
                  setState(() {
                    this.seconds = this.timer.elapsed.inSeconds;
                  });
                }
              });
            }

            startStream();
          }
        }
      } else {
        this.startIconColor = Colors.deepPurple;
        this.endIconColor = Colors.grey;
        this.direct_distance = 8;
        this.startDone = false;
        this.endDone = false;
        var database = open_database();
        var detective = new Detective(using: database);
        var detective_data = detective.retrieve(this.id).then((data) {
          this.start = data.start_spot;
          this.end = data.end_spot;
        });
        detective_data.catchError((error) {
          print("data retrieval failed: $error");
        });
        startStream();
      }

      //set all the correct this.vars for a direct only insert
      //plus the start and end locations
    } else if (this.startup == Details.review) {
      this.review_map = {};
      var database = open_database();
      var detective = new Detective(using: database);
      var detective_data = detective.retrieve(this.id).then((data) {
        //double is not a subtype of int

        this.review_map.putIfAbsent(
            "est_retrieval_time", () => data.retrieval_time.toString());
        this.review_map.putIfAbsent("start_spot", () => data.start_spot);

        this.review_map.putIfAbsent("end_spot", () => data.end_spot);
        this.review_map.putIfAbsent("user", () => data.user);

        this.review_map.putIfAbsent("details", () => data.details);

        var date = new DateTime.fromMillisecondsSinceEpoch(data.timestamp);
        this.review_map.putIfAbsent("detective_date", () => date.toString());

        this
            .review_map
            .putIfAbsent("collection_method", () => data.collection_method);
      });
      detective_data.catchError((error) {
        print("detective data retrieval failed: $error");
      });
      var direct = new Direct(using: database);
      var direct_data = direct.retrieve(this.id).then((data) {
        //double is not a subtype of int
        this.review_map.putIfAbsent(
            "actual_retrieval_time", () => data.retrieval_time.toString());

        var date = new DateTime.fromMillisecondsSinceEpoch(data.timestamp);
        this.review_map.putIfAbsent("direct_date", () => date.toString());
      });
      direct_data.catchError((error) {
        print("direct data retrieval failed: $error");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (this.startup) {
      case Details.initial:
        {
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              backgroundColor: Colors.deepPurpleAccent,
              title: Text("New Record"),
              actions: <Widget>[
                MaterialButton(
                    textColor: Colors.white,
                    color: Colors.deepPurple,
                    //run db tasks and then exit to home (refreshed)
                    onPressed: () async {
                      if (_infoKey.currentState.validate()) {
                        if (this._timeToggle != true) {
                          //while the end button validates
                          //this does not hold for map added quickies,
                          //so we revalidate here

                          if (_timeKey.currentState.validate()) {
                            if (int.tryParse(this.minutesController.text) !=
                                null) {
                              this.seconds +=
                                  int.parse(this.minutesController.text) * 60;
                            }

                            if (this.start != null && this.end != null) {
                              await this.insert();
                              Navigator.of(context).popAndPushNamed('/');
                            } else {
                              final validation_message = SnackBar(
                                key: Key("details_location_not_set_toast"),
                                content: Text(
                                    'please set start and/or end location(s)'),
                              );
                              _scaffoldKey.currentState
                                  .showSnackBar(validation_message);
                            }
                          }
                        } else {
                          if (this.start != null && this.end != null) {
                            await this.insert();

                            Navigator.of(context).popAndPushNamed('/');
                          } else {
                            final validation_message = SnackBar(
                              key: Key("details_location_not_set_toast"),
                              content: Text(
                                  'please set start and/or end location(s)'),
                            );
                            _scaffoldKey.currentState
                                .showSnackBar(validation_message);
                          }
                        }
                      }

                      //check if start and end are not null
                      //remember not to pull anything from the dict only the local values
                    },
                    child: Text("Done"),
                    key: Key("done_button")),
              ],
            ),
            body: Center(
              child: ListView(
                children: <Widget>[
                  Form(
                    key: _infoKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          child: TextFormField(
                            key: Key("name_field"),
                            controller: userController,
                            decoration: const InputDecoration(
                                hintText:
                                    "enter the interviewee's or your name..."),
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'please enter any consistent name for the record';
                              }
                              if (value.length > 42) {
                                return 'the name is too long for the main list on a phone';
                              }
                              return null;
                            },
                          ),
                          padding: EdgeInsets.all(10),
                        ),
                        Container(
                          padding: EdgeInsets.all(10),
                          child: TextFormField(
                            key: Key("details_field"),
                            controller: detailsController,
                            decoration: const InputDecoration(
                                hintText:
                                    "enter something to help you remember this trip..."),
                            validator: (value) {
                              if (value.length > 48 * 2) {
                                return 'the details are too long for the main list on a phone';
                              }
                              return null;
                            },
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Form(
                              key: _timeKey,
                              child: Container(
                                padding: EdgeInsets.all(20),
                                child: Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        key: Key("minutes_field"),
                                        controller: minutesController,
                                        enabled: _timeToggle ? false : true,
                                        keyboardType:
                                            TextInputType.numberWithOptions(),
                                        decoration: InputDecoration(
                                            helperText: "",
                                            hintText: _timeToggle
                                                //see validation on seconds
                                                ? this.seconds != 0
                                                    ? "     timer:"
                                                    : ""
                                                : "minutes..."),
                                        validator: (value) {
                                          var minutes = int.tryParse(value);
                                          if (minutes == null &&
                                              //value != "timer: " &&
                                              value.isNotEmpty) {
                                            return 'numbers only';
                                          }
                                          //we could also use the text controller
                                          //to do a split error when seconds is also wrong

                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        key: Key("seconds_field"),
                                        controller: secondsController,
                                        enabled: _timeToggle ? false : true,
                                        keyboardType:
                                            TextInputType.numberWithOptions(),
                                        decoration: InputDecoration(
                                            helperText: "",
                                            hintText: _timeToggle
                                                //dont validate seconds if _timeToggle == true, validate end and start are set
                                                ? this.seconds != 0
                                                    ? "${this.seconds} seconds"
                                                    : "auto mode"
                                                : "seconds..."),
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return 'enter time';
                                          }
                                          var seconds = int.tryParse(value);
                                          if (seconds == null) {
                                            return 'numbers only';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(5),
                              child: Switch(
                                key: Key("auto_toggle"),
                                value: _timeToggle,
                                activeTrackColor:
                                    isToggleDisabled ? Colors.grey : null,
                                activeColor:
                                    isToggleDisabled ? Colors.grey : null,
                                inactiveTrackColor:
                                    isToggleDisabled ? Colors.grey : null,
                                inactiveThumbColor:
                                    isToggleDisabled ? Colors.grey : null,
                                onChanged: (bool value) {
                                  setState(() {
                                    if (!isToggleDisabled) {
                                      _timeToggle = value;
                                      isMapDisabled = value;
                                      if (value == true) {
                                        final toggle_message = SnackBar(
                                          content: Text(
                                              'entering auto mode for self retrieval'),
                                        );
                                        _scaffoldKey.currentState
                                            .showSnackBar(toggle_message);
                                      }
                                    }
                                  });
                                },
                              ),
                            ),
                            Container(
                              height: 70,
                              padding: EdgeInsets.all(5),
                              child: MaterialButton(
                                key: Key("map_button"),
                                color: isMapDisabled
                                    ? Colors.grey
                                    : Colors.deepPurple,
                                textColor: Colors.white,
                                child: Text("Map"),
                                onPressed: isMapDisabled
                                    ? null
                                    : () {
                                        Navigator.of(context).popAndPushNamed(
                                            '/map',
                                            arguments: [
                                              this.id,
                                              this.match,
                                              {
                                                "user": userController.text,
                                                "details":
                                                    detailsController.text,
                                                "minutes":
                                                    minutesController.text,
                                                "est_seconds":
                                                    secondsController.text,
                                                "time_toggle": _timeToggle,
                                                "start": this.start,
                                                "end": this.end,
                                                "seconds": this.seconds,
                                              }
                                            ]);
                                      },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.all(25),
                          child: MaterialButton(
                            key: Key("start_button"),
                            disabledColor: Colors.grey,
                            color: startIconColor,
                            padding: EdgeInsets.all(40),
                            child: Text("Start"),
                            onPressed: this.isStartDisabled
                                ? null
                                : start_button_action,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(25),
                          child: MaterialButton(
                            key: Key("end_button"),
                            disabledColor: Colors.grey,
                            color: endIconColor,
                            padding: EdgeInsets.all(40),
                            child: Text("End"),
                            onPressed:
                                this.isEndDisabled ? null : end_button_action,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Slider(
                    value: this.location_wait,
                    onChanged: (value) {
                      setState(() {
                        this.location_wait = value;
                      });
                    },
                    min: 1,
                    max: 60,
                  ),
                  Center(
                    child: Column(
                      children: <Widget>[
                        Text(
                            "will ask for the location ${this.location_wait.toStringAsFixed(0)} times"),
                        Text("to make sure we get the best accuracy")
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        break;
      case Details.direct:
        {
          return Scaffold(
            key: this._scaffoldKey,
            appBar: AppBar(
              backgroundColor: Colors.deepPurpleAccent,
              title: Text("Add Direct"),
              actions: <Widget>[
                MaterialButton(
                  textColor: Colors.white,
                  color: Colors.deepPurple,
                  //run db tasks and then exit to home (refreshed)
                  onPressed: () async {
                    if (this.startDone == true && this.endDone == true) {
                      await this.insert();
                      Navigator.of(context).popAndPushNamed('/');
                    } else {
                      final not_done_message = SnackBar(
                        key: Key("direct_location_not_set_toast"),
                        content: Text(
                            'must travel to both start and end locations before finishing'),
                      );
                      _scaffoldKey.currentState.showSnackBar(not_done_message);
                    }
                  },
                  child: Text("Done"),
                  key: Key("done_button"),
                ),
              ],
            ),
            body: Center(
              child: ListView(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(30),
                    child: Center(
                      child: Row(
                        children: <Widget>[
                          Text(
                            "${this.seconds} seconds elapsed",
                            style: TextStyle(fontSize: 25),
                            key: Key("timer_text"),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10),
                          ),
                          MaterialButton(
                            key: Key("map_button"),
                            child: Text("Map"),
                            textColor: Colors.white,
                            padding: EdgeInsets.all(30),
                            onPressed: () {
                              Navigator.of(context)
                                  .popAndPushNamed('/map', arguments: [
                                this.id,
                                this.match,
                                {
                                  //these two are probably the source of our button confusion
                                  "startDone": this.startDone,
                                  "endDone": this.endDone,
                                  "start": this.start,
                                  "end": this.end,
                                  "seconds": this.seconds,
                                  "direct_distance": this.direct_distance,
                                  "timer": this.timer,
                                  "tick": this.tick,
                                }
                              ]);
                            },
                            color: Colors.deepPurple,
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(25),
                    child: MaterialButton(
                      key: Key("direct_start_button"),
                      padding: EdgeInsets.all(40),
                      child: Text("Start"),
                      color: this.startIconColor,
                      onPressed: () {},
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(25),
                    child: MaterialButton(
                      key: Key("direct_end_button"),
                      padding: EdgeInsets.all(40),
                      child: Text("End"),
                      color: this.endIconColor,
                      onPressed: () {},
                    ),
                  ),
                  Slider(
                    value: this.direct_distance,
                    onChanged: (value) {
                      setState(() {
                        this.direct_distance = value;
                      });
                    },
                    min: 1.0,
                    max: 17.0,
                  ),
                  Center(
                    child: Column(
                      children: <Widget>[
                        Text(
                            "must be closer than ${this.direct_distance.toStringAsFixed(1)} meters to engage target"),
                        Padding(
                          padding: EdgeInsets.all(5),
                        ),
                        Text(
                            "the start is ${this.startDistance.toStringAsFixed(1)}m away from you"),
                        Text(
                            "the end is ${this.endDistance.toStringAsFixed(1)}m away from you"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        break;
      case Details.review:
        {
          return Scaffold(
            appBar: AppBar(
              title: Text("Review"),
            ),
            body: Center(
              child: Column(
                children: <Widget>[
                  Text(
                      "detective retrieval date: ${this.review_map["detective_date"]}"),
                  Text(
                      "direct retrieval date: ${this.review_map["direct_date"]}"),
                  Text(
                      "detective retrieval time: ${this.review_map["est_retrieval_time"]} seconds"),
                  Text(
                      "direct retrieval time ${this.review_map["actual_retrieval_time"]} seconds"),
                  Text(
                      "collection method: ${this.review_map["collection_method"]}"),
                  Text("start spot: ${this.review_map["start_spot"]}"),
                  Text("end spot ${this.review_map["end_spot"]}"),
                  Text("user: ${this.review_map["user"]}"),
                  Text("details: ${this.review_map["details"]}"),
                ],
              ),
            ),
          );
        }
        break;
    }
  }

  //each of the following functions can and must be enumed
  Future<void> insert() async {
    if (this.startup == Details.initial) {
      var was_map = null;

      if (this.state != null) {
        if (this.state.containsKey('set_with_map')) {
          was_map = this.state['set_with_map'];
        }
      }

      if (this._timeToggle == true || was_map != null) {
        var database = open_database();
        var detective = new Detective(using: database);

        var data = new DetectiveData(
            retrieval_time: this._timeToggle
                ? this.seconds
                : int.parse(this.secondsController.text),
            start_spot: this.start,
            end_spot: this.end,
            user: this.userController.text,
            details: this.detailsController.text,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            collection_method: "self");
        await detective.insert(data);
      } else {
        var database = open_database();
        var detective = new Detective(using: database);

        var detective_data = new DetectiveData(
            retrieval_time: int.parse(this.secondsController.text),
            start_spot: this.start,
            end_spot: this.end,
            user: this.userController.text,
            details: this.detailsController.text,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            collection_method: "memory");
        await detective.insert(detective_data);

        var direct = new Direct(using: database);

        var direct_data = new DirectData(
            start_spot: this.start,
            end_spot: this.end,
            retrieval_time: this.seconds,
            timestamp: DateTime.now().millisecondsSinceEpoch);
        await direct.insert(direct_data);
      }
    } else if (this.startup == Details.direct) {
      var database = open_database();
      var direct = new Direct(using: database);

      var direct_data = new DirectData(
          start_spot: this.start,
          end_spot: this.end,
          retrieval_time: this.seconds,
          timestamp: DateTime.now().millisecondsSinceEpoch);
      await direct.insert(direct_data);
    }
  }

  void start_button_action() async {
    if (_timeToggle == false && this.start == null) {
      if (!_timeKey.currentState.validate()) {
        return;
      }
    }
    var location_data;
    var location_stream = await startStream();
    var wait_count = 0;
    final wait_message = SnackBar(
      content: Text('please wait for accurate location...'),
    );
    _scaffoldKey.currentState.showSnackBar(wait_message);
    await for (LocationData chunk in location_stream) {
      if (wait_count > this.location_wait.toInt()) {
        location_data = chunk;
        break;
      }
      wait_count++;
    }
    setState(() {
      if (_timeToggle == true && this.start == null) {
        //start periodic timer and elapsed timer

        this.start = "${location_data.latitude}, ${location_data.longitude}";
        this.secondsController.text = "";
        this.minutesController.text = "";
        this.timer = Stopwatch();
        this.timer.start();
        this.tick = Timer.periodic(Duration(seconds: 1), (timer) {
          if (this.seconds != this.timer.elapsed.inSeconds) {
            setState(() {
              this.seconds = this.timer.elapsed.inSeconds;
            });
          }
        });
        isToggleDisabled = true;
        this.startIconColor = Colors.deepPurple;

        final start_message = SnackBar(
          content: Text('please travel to the end location'),
        );
        _scaffoldKey.currentState.showSnackBar(start_message);
      } else if (_timeToggle == false && this.start == null) {
        if (_timeKey.currentState.validate()) {
          this.start = "${location_data.latitude}, ${location_data.longitude}";
          this.isMapDisabled = true;
          this.timer = Stopwatch();
          this.timer.start();
          isToggleDisabled = true;
          this.startIconColor = Colors.deepPurple;

          final start_message = SnackBar(
            content: Text('please travel to the end location'),
          );
          _scaffoldKey.currentState.showSnackBar(start_message);
        }

        //validate seconds field and start elapsed timer
      } else {
        final error_message = SnackBar(
          key: Key("already_started_toast"),
          content: Text("you've already started"),
        );
        _scaffoldKey.currentState.showSnackBar(error_message);
      }
    });
  }

  void end_button_action() async {
    if (this.start != null && _timeToggle == true) {
      this.tick.cancel();
      this.timer.stop();
    }
    var location_data;
    var location_stream = await startStream();
    var wait_count = 0;
    final wait_message = SnackBar(
      content: Text('please wait for accurate location...'),
    );
    _scaffoldKey.currentState.showSnackBar(wait_message);
    await for (LocationData chunk in location_stream) {
      if (wait_count > this.location_wait.toInt()) {
        location_data = chunk;
        break;
      }
      wait_count++;
    }

    setState(() {
      if (this.start != null && _timeToggle == true) {
        this.end = "${location_data.latitude}, ${location_data.longitude}";
        this.seconds = this.timer.elapsed.inSeconds;
        this.isEndDisabled = true;
        this.isStartDisabled = true;
//remove this so they cant yeet their coords after a time is recorded in auto
        this.isMapDisabled = false;
      } else if (this.start != null && _timeToggle == false) {
        this.end = "${location_data.latitude}, ${location_data.longitude}";
        this.timer.stop();
        this.seconds = this.timer.elapsed.inSeconds;
        this.isEndDisabled = true;
        this.isStartDisabled = true;
        this.isMapDisabled = false;
        final success_message = SnackBar(
            key: Key("end_success"), content: Text("end location set"));
        _scaffoldKey.currentState.showSnackBar(success_message);
      } else {
        final error_message = SnackBar(
          key: Key("end_before_start_toast"),
          content: Text('you must set a start location first'),
        );
        _scaffoldKey.currentState.showSnackBar(error_message);
      }
    });
  }

  void checkDistance(Stream<LocationData> location_stream) async {
    await for (LocationData location_data in location_stream) {
      if (startDone == true && endDone == true || stop_stream == true) {
        break;
      }
      if (startDone == false && this.start != null) {
        var startList = this.start.split(",").map((string) {
          return double.parse(string);
        }).toList();

        var distance = calculate(location_data.latitude,
            location_data.longitude, startList[0], startList[1]);
        setState(() {
          this.startDistance = distance;
        });
        print("the distance to the start is $distance meters");
        if (distance < this.direct_distance) {
          setState(() {
            this.startIconColor = Colors.green;
            this.endIconColor = Colors.deepPurple;
            final travel_message = SnackBar(
              content: Text('please travel to the end location'),
            );
            _scaffoldKey.currentState.showSnackBar(travel_message);
            this.timer = Stopwatch();
            this.timer.start();
            this.tick = Timer.periodic(Duration(seconds: 1), (timer) {
              if (this.seconds != this.timer.elapsed.inSeconds) {
                setState(() {
                  this.seconds = this.timer.elapsed.inSeconds;
                });
              }
            });
            this.startDone = true;
          });
        }
      } else {
        if (this.endDone == false && this.end != null) {
          var endList = this.end.split(",").map((string) {
            return double.parse(string);
          }).toList();

          var distance = calculate(location_data.latitude,
              location_data.longitude, endList[0], endList[1]);
          setState(() {
            this.endDistance = distance;
          });
          print("the distance to the end is: $distance meters");
          if (distance < this.direct_distance) {
            setState(() {
              this.isStartDisabled = true;
              this.isEndDisabled = true;
              this.endIconColor = Colors.red;
              final travel_message = SnackBar(
                content: Text('detected end location'),
              );
              _scaffoldKey.currentState.showSnackBar(travel_message);
              this.endDone = true;
              this.tick.cancel();
              this.timer.stop();
              this.seconds = this.timer.elapsed.inSeconds;
            });
          }
        }
      }

      //var distance_from_location = ;

      //do the distance check
      //if within distance
      //if startDone make end red else make start green
    }
  }

  Future<Stream<LocationData>> startStream() async {
    final Location location = Location();
    final permissions = await location.requestPermission();
    location.changeSettings(accuracy: LocationAccuracy.HIGH);
    if (permissions == true) {
      if (this.startup == Details.direct) {
        checkDistance(location.onLocationChanged());
        return null;
      } else if (this.startup == Details.initial) {
        return location.onLocationChanged();
      }
    } else {
      final location_message = SnackBar(
        content: Text('cannot get location without permission'),
      );
      _scaffoldKey.currentState.showSnackBar(location_message);
    }
  }

  //aparently this is it, no pi needed unless its radian?
  double calculate(double latitude1, double longitude1, double latitude2,
      double longitude2) {
    //courtesy of the haversine package
    var lat1 = toRadians(latitude1);
    var lon1 = toRadians(longitude1);
    var lat2 = toRadians(latitude2);
    var lon2 = toRadians(longitude2);
    var EarthRadius = 6378137.0;
    double distance = 2 *
        EarthRadius *
        asin(sqrt(pow(sin(lat2 - lat1) / 2, 2) +
            cos(lat1) * cos(lat2) * pow(sin(lon2 - lon1) / 2, 2)));

    return distance;
  }

  double toRadians(double degree) {
    return degree * pi / 180;
  }

  @override
  void dispose() {
    this.stop_stream = true;
    if (this.tick != null) {
      this.tick.cancel();
    }

    super.dispose();
  }
}

enum Details { initial, direct, review }
