import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:labshare/network/session.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

enum UiStage { idle, scanning, received, saved }

class _StudentScreenState extends State<StudentScreen> {
  Session? session;
  UiStage uiStage = UiStage.idle;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    session = Session.student();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    session?.stop();
  }

  void scan() async {
    setState(() {
      uiStage = UiStage.scanning;
    });
    await session?.start();
    var bytes = session!.chunkToFile();

    setState(() {
      uiStage = UiStage.received;
    });

    String? outputFileName = await FilePicker.platform.saveFile(
      bytes: bytes,
      fileName: session?.fileName,
    );

    if (outputFileName != null) {
      File file = File(outputFileName);
      await file.writeAsBytes(bytes);
    }

    setState(() {
      uiStage = UiStage.saved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Student Dash")),
      body: switch (uiStage) {
        (UiStage.idle) => Center(
          child: MaterialButton(onPressed: scan, child: Text("Start Scan")),
        ),
        (UiStage.scanning) => Center(child: Text("Scanning and downloading")),
        (UiStage.received) => Center(child: Text("Saving File...")),
        (UiStage.saved) => Center(child: Text("Completed")),
      },
    );
  }
}
