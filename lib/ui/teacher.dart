import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:labshare/network/session.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

enum Stage { filePick, processing, advertising }

class _TeacherScreenState extends State<TeacherScreen> {
  @override
  void initState() {
    super.initState();
  }

  Stage uiStage = Stage.filePick;
  Session? session;

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        uiStage = Stage.processing;
      });
      File file = File(result.files.single.path!);
      var bytes = await file.readAsBytes();
      session = Session.teacher(
        fileName: result.files.single.name,
        file: bytes,
      );
      session?.start();
      setState(() {
        uiStage = Stage.advertising;
      });
    } else {
      // User canceled the picker
    }
  }

  @override
  void dispose() {
    super.dispose();
    session?.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Teacher Dash")),
      body: switch (uiStage) {
        (Stage.filePick) => Center(
          child: MaterialButton(onPressed: pickFile, child: Text("PickFile")),
        ),
        (Stage.processing) => Center(child: Text("Processing...")),
        (Stage.advertising) => Center(child: Text("Advertising...")),
      },
    );
  }
}
