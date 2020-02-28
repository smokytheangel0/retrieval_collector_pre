import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:location/location.dart';

class MapView extends StatefulWidget {
  MapView({Key key, this.id, this.match, this.state}) : super(key: key);
  final String id;
  final bool match;
  final Map<String, dynamic> state;
  @override
  _MapViewState createState() =>
      _MapViewState(id: this.id, match: this.match, state: this.state);
}

class _MapViewState extends State<MapView> {
  final String id;
  final bool match;
  Map<String, dynamic> state;

  bool selectStart = null;
  Marker startMarker = null;
  bool selectEnd = null;
  Marker endMarker = null;
  bool areButtonsEnabled = true;
  Color startIconColor = Colors.green;
  Color endIconColor = Colors.red;
  bool firstLocation = false;
  Map<MarkerId, Marker> markerList = <MarkerId, Marker>{};
  MarkerId selectedMarker;

  _MapViewState({this.id, this.match, this.state});

  Completer<GoogleMapController> _controller = Completer();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  var update = false;

  @override
  void initState() {
    super.initState();

    if (this.match != null) {
      this.areButtonsEnabled = false;
      this.state["used_map"] = true;
    }
    if (this.state.containsKey("time_toggle")) {
      if (this.state["time_toggle"] == true) {
        this.areButtonsEnabled = false;
      }
    }

    if (this.state['end'] != null) {
      this.selectEnd = false;
      var endList = this.state['end'].split(", ").map((string) {
        return double.parse(string);
      }).toList();
      MarkerId selectedMarker = MarkerId("end");
      var endMarker = Marker(
        markerId: selectedMarker,
        position: LatLng(endList[0], endList[1]),
        draggable: false,
      );
      this.markerList[selectedMarker] = endMarker;
      this.endIconColor = Colors.grey;
    }

    if (this.state['start'] != null) {
      this.selectStart = false;
      var startList = this.state['start'].split(",").map((string) {
        return double.parse(string);
      }).toList();
      MarkerId selectedMarker = MarkerId("start");
      var startMarker = Marker(
        markerId: selectedMarker,
        position: LatLng(startList[0], startList[1]),
        draggable: false,
      );
      this.markerList[selectedMarker] = startMarker;
      this.startIconColor = Colors.grey;
    }
    //handle match to make an immutable map if match != null
  }

  void retry() {
    Navigator.of(context)
        .popAndPushNamed('/map', arguments: [this.id, this.match, this.state]);
  }

  /*
  Future<void> waitForRefresh() async {
    var shouldUpdate = this.update;
    while (shouldUpdate != true) {
      shouldUpdate = this.update;
    }
    setState(() {
      this.update = false;
    });
  }
  */

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          //if match != null this should be a normal back button

          backgroundColor: Colors.deepPurpleAccent,
          title: Text("Location Selector"),
          actions: <Widget>[
            FlatButton(
              key: Key("map_done_button"),
              color: Colors.deepPurple,
              textColor: Colors.white,
              child: Text("Done"),
              //pass state back to calling view
              onPressed: () {
                if (this.state['start'] == null || this.state['end'] == null) {
                  final snackBar = SnackBar(
                    key: Key("map_location_not_set_toast"),
                    content: Text('one of the locations is not set!'),
                  );

                  _scaffoldKey.currentState.showSnackBar(snackBar);
                } else {
                  Navigator.of(context).popAndPushNamed('/details',
                      arguments: [this.id, this.match, this.state]);
                }
              },
            )
          ],
        ),
        body: FutureBuilder<CameraPosition>(
          future: getLocation(),
          builder:
              (BuildContext context, AsyncSnapshot<CameraPosition> snapshot) {
            if (snapshot.hasData) {
              //if (markerList.isNotEmpty) {
                return GoogleMap(
                  key: Key("map"),
                  onTap: select,
                  markers: Set<Marker>.of(markerList.values),
                  mapType: MapType.satellite,
                  initialCameraPosition: snapshot.data,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                );
              /*
              } else {
                return GoogleMap(
                  key: Key("map"),
                  onTap: select,
                  mapType: MapType.satellite,
                  initialCameraPosition: snapshot.data,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                );
              }
              */
            } else {
              return Center(
                child: Container(
                  child: MaterialButton(
                    child:
                        Text("Must have location permission for Maps to work"),
                    color: Colors.yellow,
                    textColor: Colors.black,
                  ),
                ),
              );
            }
          },
        ),
        //these can be null if match is not null so the map is immutable
        floatingActionButton: this.areButtonsEnabled
            ? Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: EdgeInsets.only(left: 31),
                      child: FloatingActionButton(
                        backgroundColor: Colors.deepPurpleAccent,
                        key: Key("delete_button"),
                        onPressed: () {
                          final warning_message = SnackBar(
                            key: Key("clear_locations_toast"),
                            content: Text('clear locations?'),
                            action: SnackBarAction(
                              key: Key("clear_locations_accept"),
                              textColor: Colors.yellow,
                              label: "blow 'em away!",
                              onPressed: () {
                                this.state['start'] = null;
                                this.state['end'] = null;
                                this.state['set_with_map'] = null;
                                markerList.clear();
                                Navigator.of(context)
                                    .popAndPushNamed('/details', arguments: [
                                  this.id,
                                  this.match,
                                  this.state
                                ]);
                              },
                            ),
                          );
                          _scaffoldKey.currentState
                              .showSnackBar(warning_message);
                        },
                        heroTag: null,
                        child: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: EdgeInsets.only(top: 125),
                      child: FloatingActionButton(
                        key: Key("refresh_button"),
                        onPressed: retry,
                        heroTag: null,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.gps_fixed),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: EdgeInsets.only(left: 30),
                      child: FloatingActionButton.extended(
                        key: Key("map_start_button"),
                        onPressed: () {
                          if (this.selectStart == false) {
                            //toast start has already been set
                            final snackBar = SnackBar(
                              key: Key("start_already_set_toast"),
                              content: Text(
                                  'the start location has already been set!'),
                            );
                            _scaffoldKey.currentState.showSnackBar(snackBar);
                          }
                          if (this.selectEnd == true) {
                            final snackBar = SnackBar(
                                key: Key(
                                    "start_pressed_while_setting_end_toast"),
                                content: Text(
                                    'please tap a location to finish setting the end first'));

                            _scaffoldKey.currentState.showSnackBar(snackBar);
                          }
                          setState(
                            () {
                              if (this.selectStart != false &&
                                  this.selectEnd != true) {
                                this.startIconColor = Colors.deepPurple;
                                this.selectStart = true;
                              }
                            },
                          );
                        },
                        label: Text("start"),
                        heroTag: null,
                        backgroundColor: this.startIconColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton.extended(
                      key: Key("map_end_button"),
                      onPressed: () {
                        if (this.selectEnd == false) {
                          final snackBar = SnackBar(
                            key: Key("end_already_set_toast"),
                            content: Text(
                                'the end location has already been set!'),
                          );
                          

                          _scaffoldKey.currentState.showSnackBar(snackBar);
                        }
                        if (this.selectStart == true) {
                          final snackBar = SnackBar(
                            key: Key("end_pressed_while_setting_start_toast"),
                            content: Text(
                                'please tap a location to finish setting the start first'),
                          );

                          _scaffoldKey.currentState.showSnackBar(snackBar);
                        }
                        setState(
                          () {
                            if (this.selectEnd != false &&
                                this.selectStart != true) {
                              this.endIconColor = Colors.deepPurple;
                              this.selectEnd = true;
                            }
                          },
                        );
                      },
                      label: Text("end"),
                      heroTag: null,
                      backgroundColor: this.endIconColor,
                    ),
                  ),
                ],
              )
            : null,
      ),
      onWillPop: () async {
        //this pops just like the done button now
        //reset the waypoints to null if only one is set
        if (this.state['start'] == null || this.state['end'] == null) {
          this.state['start'] = null;
          this.state['end'] = null;
        }
        Navigator.of(context).popAndPushNamed('/details',
            arguments: [this.id, this.match, this.state]);
        return false;
      },
    );
    
  }

  void refresh() {}

  void select(LatLng location) {
    if (this.selectStart == null && this.selectEnd == null) {
      final snackBar = SnackBar(
        key: Key("location_selected_before_button_toast"),
        content: Text('please select start or end to set a location'),
      );

      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
    if (this.selectStart == true) {
      selectedMarker = MarkerId("start");
      setState(() {
        this.state['start'] = "${location.latitude}, ${location.longitude}";
        this.state['set_with_map'] = true;
        var startMarker = Marker(
          markerId: selectedMarker,
          position: LatLng(location.latitude, location.longitude),
          draggable: false,
        );
        this.markerList[selectedMarker] = startMarker;
        this.selectStart = false;
        this.startIconColor = Colors.grey;
      });
      /* might put a switch on this and the one below to toggle it as an option
      final snackBar = SnackBar(
        content: Text('start location is set to: ${this.state['start']}'),
      );

      _scaffoldKey.currentState.showSnackBar(snackBar);
      */
    }
    if (this.selectEnd == true) {
      selectedMarker = MarkerId("end");
      setState(() {
        this.state['end'] = "${location.latitude}, ${location.longitude}";
        this.state['set_with_map'] = true;
        var endMarker = Marker(
          markerId: selectedMarker,
          //not doing the lats and longs right
          position: LatLng(location.latitude, location.longitude),
          draggable: false,
        );
        this.markerList[selectedMarker] = endMarker;
        this.selectEnd = false;
        this.endIconColor = Colors.grey;
      });
      /*
      final snackBar = SnackBar(
        content: Text('end location is set to: ${this.state['end']}'),
      );

      _scaffoldKey.currentState.showSnackBar(snackBar);
      */
    }
  }

  Future<CameraPosition> getLocation() async {
    final Location location = Location();
    final permissions = await location.requestPermission();
    location.changeSettings(accuracy: LocationAccuracy.HIGH);
    if (permissions == true) {
      var camera_location = await location.getLocation();
      var cameraPosition = CameraPosition(
        target: LatLng(camera_location.latitude, camera_location.longitude),
        zoom: 20.0,
      );

      return cameraPosition;
    } else {
      final location_message = SnackBar(
        content: Text('cannot center on location without permission'),
      );
      _scaffoldKey.currentState.showSnackBar(location_message);
      var defaultCameraPosition =
          CameraPosition(target: LatLng(42.0, 42.0), zoom: 1.0);

    }
  }
}
