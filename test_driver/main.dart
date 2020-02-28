import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_driver_fast_restart/flutter_driver_fast_restart.dart';
import 'package:james_data/main.dart';
import 'package:flutter/material.dart';

void main() async {
  
  final restartController = RestartController();

  enableFlutterDriverExtension(
    handler: (request) async {
      restartController.add(request);
      return "";
    }
  );

 
  runApp(
    RestartWidget(
      restartController: restartController,
      builder: (context, data) => RetrievalCollector(), 
    )
  );
  /*
  enableFlutterDriverExtension();
  app.main();
  */
}