import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:labshare/app.dart';
import 'package:labshare/network/session.dart';
import 'package:labshare/protocol.dart';

void main() {
  runApp(const App());
  // WidgetsFlutterBinding.ensureInitialized();

  // const size = 2 * chunkSize + 40;

  // var file = Uint8List(size)
  //   ..setAll(0, List.generate(size, (index) => index & 1));

  // var session = Session.teacher(file: file, fileName: "Test.txt");
  // var session = Session.student();
  // session.start();
}
