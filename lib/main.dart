import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:labshare/network/mdns.dart';
import 'package:labshare/network/session.dart';
import 'package:labshare/protocol.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // var session = Session.teacher(
  //   file: Uint8List(2 * chunkSize + 100)
  //     ..setAll(0, List.filled(2 * chunkSize + 100, 1)),
  //   fileName: "Test.txt",
  // );
  var session = Session.student();
  session.start();
}
