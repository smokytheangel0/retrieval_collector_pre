import 'package:flutter/material.dart';
import 'package:james_data/main.dart';
import 'package:james_data/details.dart';
import 'package:james_data/main_controller.dart';
import 'package:james_data/map.dart';
import 'dart:async';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
            builder: (BuildContext context) => MainListView());
      case '/details':
        // Validation of correct data type
        if (args is List) {
          return MaterialPageRoute(
            builder: (_) =>
                DetailsView(id: args[0], match: args[1], state: args[2]),
          );
        }
        // If args is not of the correct type, return an error page.
        // You can also throw an exception while in development.
        return _errorRoute();
      case '/map':
        if (args is List) {
          return MaterialPageRoute(
            builder: (_) =>
                MapView(id: args[0], match: args[1], state: args[2]),
          );
        }

        return _errorRoute();
      default:
        // If there is no such named route in the switch statement, e.g. /third
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('ERROR'),
        ),
      );
    });
  }
}
