import 'package:flutter/material.dart';
import 'package:labshare/network/mdns.dart';
import 'package:labshare/network/session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  var session = Session(Mode.student);
  session.start();
}
