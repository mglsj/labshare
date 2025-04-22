import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:labshare/network/mdns.dart';
import 'package:labshare/network/session.dart';
import 'package:labshare/protocol.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  var file = Uint8List(2 * chunkSize + 100)
    ..setAll(0, List.generate(2 * chunkSize + 40, (index) => index & 1));
  // print(file);

  var session = Session.teacher(file: file, fileName: "Test.txt");
  // var session = Session.student();
  session.start();
}
