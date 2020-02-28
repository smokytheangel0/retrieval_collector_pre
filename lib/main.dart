import 'package:flutter/material.dart';
import 'package:james_data/route_generator.dart';
import 'package:james_data/main_controller.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  //enableFlutterDriverExtension();

  runApp(RetrievalCollector());
}

class RetrievalCollector extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: '/',
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}

class MainListView extends StatefulWidget {
  MainListView({Key key}) : super(key: key);

  @override
  _ListViewState createState() => _ListViewState();
}

class _ListViewState extends State<MainListView> {
  Future<List<ListTile>> _items;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
    });
  }

  @override
  void initState() {
    super.initState();
    _items = get_list(context);
  }

  //we might need this later when the entries are many
  void _retry() {
    setState(() {
      _items = get_list(context);
    });
  }

  ///TODO
  ///thank you for your work so far we have a little left to go (despite the long description of the first)

  ///day 2
  ///abstract details view to cover all three enums
  ///we may be able to ignore review,
  ///but map pins are now functional from details state and map state
  ///so the way forward to immutable pins is pretty clear
  ///and we also now have a retrieve method on detective
  ///the same will be necesary for direct in order to do a review screen
  ///DAMN CLOSE TO THIS ONE, JUST NEED TO WRITE A NEW HAVERSINE FUNCTION
  ///
  ///truncate the id (ONLY) before inserting into db, so we group more quasi duplicates
  ///right now the lat and long are so sensitive that they will never match unless
  ///a radius is applied, which we shouldnt do in the model in order to keep the db simple
  ///the radius should only be applied during completion of a direct for an unpaired detective
  ///and the location data there is just copied from the detective example exactly
  ///we can use the haversine package which returns a distance in meters during completion of direct
  ///in order to make the truncation work though, i think detective needs to be the only one that calls
  ///history on duplicates, so that a matching direct is always flushed if there is one, that way
  ///the records (and UI) dont overlap on accident; we can use the map to determine the level of truncation we want
  ///probably start capping at 3 decimal places this is a couple car lengths apart, but make sure
  ///to use changeSettings on the location class to set the location accuracy to high only
  ///we also need a history tab at least for field tests to make sure near-dupes are getting flushed
  ///and but before that I think db_test needs one more, it shouldnt be hard to make sure the
  ///basic rules are being followed
  ///
  ///
  ///

  ///WEEK 2
  ///refactor this whole lot for better maintainability and
  ///to pass all the lints
  ///
  ///going through each file will also make sure
  ///you don't miss things like long press to delete list items
  ///
  ///remember, this code will be looked at as proof of provinance for the data collected
  ///even something like not driving every est retrieval as self, or the fact
  ///that self is not discriminated from an interview, can skew the results
  ///
  ///do export function
  ///you might be able to do this via email
  ///if your csv recombiner can
  ///ignore inserting any perfectly equal records
  ///if possible the recombined master csv should be able
  ///to be posted online and dled in another function to
  ///show activity graphs

  ///I BELIEVE the timers and start and end are correctly implemented but
  ///the solution was so tricky that I lost my place many times
  ///so there may be many bugs present, so you should make some tests for it
  ///don't be afraid to add test suggestions as comments as you think of them

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: this._scaffoldKey,
      appBar: AppBar(
        title: Text("Retrieval Collector", key: Key("title_text")),
      ),
      body: FutureBuilder<List<ListTile>>(
        future: _items,
        builder:
            (BuildContext context, AsyncSnapshot<List<ListTile>> snapshot) {
          if (snapshot.hasData) {
            return Center(
                child: ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                return snapshot.data[index];
              },
            ));
          } else {
            //and this would be a widget that says its not ready yet
            return Center(
              child: Container(
                child: Text('Gathering entries...'),
                padding: EdgeInsets.all(30),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        
        backgroundColor: Colors.deepPurpleAccent,
        key: Key("add_button"),
        onPressed: () {
          final version_message = SnackBar(
            content: Text('Version 0.0.14'),
          );
          _scaffoldKey.currentState.showSnackBar(version_message);

          Navigator.of(context).pushNamed(
            '/details',
            arguments: [null, null, null],
          );
        },        
        child: Icon(Icons.add),
      ),
    );
  }
}

/*

*/
