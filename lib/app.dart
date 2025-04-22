import 'package:flutter/material.dart';
import 'package:labshare/home.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: "LabShare", home: HomeScreen());
  }
}
