import 'package:james_data/main.dart';
import 'package:james_data/model.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

Future<List<ListTile>> get_list(BuildContext context) async {
  var database = open_database();
  var detective = new Detective(using: database);
  var direct = new Direct(using: database);
  var detective_list = await detective.entry_list();
  var direct_list = await direct.entry_list();

  List<ListTile> widget_list = new List();

  //this quadratic time loop is probably
  //the first place we need to optimize
  var key_number = 0;
  for (var detect in detective_list) {
    var match = false;
    for (var item in direct_list) {
      if (detect["id"] == item["id"]) {
        //build a matched list tile
        widget_list.add(new ListTile(
          key: Key("tile_$key_number"),
          title: Text(detect["user"]),
          subtitle: Text(detect["details"]),
          isThreeLine: true,
          trailing: Icon(Icons.check_circle, key: Key("complete_icon")),
          onTap: () {
            Navigator.of(context).pushNamed(
              '/details',
              arguments: [detect['id'], true, null],
            );
          }, //details view, pass id and match status
          //onLongPress: , //toast are you sure you want to delete '$details' or cannot delete matched pair
        ));
        match = true;
        key_number += 1;
      }
    }
    if (match == false) {
      //build an unmatched listtile
      widget_list.add(new ListTile(
        key: Key("tile_$key_number"),
        //called on null (detect[])
        title: Text(detect["user"]),
        subtitle: Text(detect["details"]),
        isThreeLine: true,
        //transfer within a station accounts for
        trailing: Icon(
          Icons.transfer_within_a_station,
          key: Key("detective_icon"),
        ),
        onTap: () {
          Navigator.of(context).pushNamed(
            '/details',
            arguments: [detect['id'], false, null],
          );
        }, //details view, pass id
        //onLongPress: ,//toast are you sure you want to delete '$details' or cannot delete matched pair
      ));
      key_number += 1;
    }
  }
  if (widget_list.isEmpty) {
    widget_list.add(ListTile(
      key: Key("tile_$key_number"),
      title: Text("There are no items yet"),
      subtitle: Text("press the plus to add a record"),
      isThreeLine: true,
    ));
  }
  return widget_list;
}
