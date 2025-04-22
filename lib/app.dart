import 'package:flutter/material.dart';
import 'package:labshare/router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "LabShare",
      onGenerateTitle: (context) => "LabShare",
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
