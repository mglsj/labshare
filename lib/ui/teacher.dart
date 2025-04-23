import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:labshare/network/session.dart';
import 'package:labshare/widgets/window_buttons.dart';
import 'package:window_manager/window_manager.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

enum Stage { initial, filePick, processing, advertising }

class _TeacherScreenState extends State<TeacherScreen> with WindowListener {
  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();

    session?.stop();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();

    if (isPreventClose) {
      showDialog(
        context: context,
        builder: (context) {
          return ContentDialog(
            title: Text('Close Window'),
            content: Text('Are you sure you want to close the window?'),
            actions: [
              Button(
                onPressed: () async {
                  await session?.stop();
                  await windowManager.destroy();
                },
                child: Text('Close'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );
    }
  }

  Stage uiStage = Stage.initial;
  Session? session;

  void pickFile() async {
    setState(() {
      uiStage = Stage.filePick;
    });

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
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: Text('LabShare | Faculty'),
        leading: IconButton(
          icon: Icon(FluentIcons.back),
          onPressed: () {
            session?.stop();
            context.pushReplacementNamed("home");
          },
        ),
        automaticallyImplyLeading: false,
        actions: WindowButtons(),
      ),
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: switch (uiStage) {
            (Stage.initial) => [
              Text("Pick a file to start", style: TextStyle(fontSize: 40)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: pickFile,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    EdgeInsets.fromLTRB(20, 10, 20, 10),
                  ),
                ),
                child: Text(
                  "Browse",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
                ),
              ),
            ],
            (Stage.filePick) => [
              Text(
                "Continue on the file picker.",
                style: TextStyle(fontSize: 40),
              ),
            ],

            (Stage.processing) => [
              Text("Processing File...", style: TextStyle(fontSize: 40)),
              const SizedBox(height: 20),
              ProgressRing(),
            ],

            (Stage.advertising) => [
              Text("File is being shared", style: TextStyle(fontSize: 40)),
              const SizedBox(height: 20),
              ProgressBar(),
              const SizedBox(height: 10),
              Button(
                child: Text("Close"),
                onPressed: () async {
                  await session!.stop();
                  context.pushReplacementNamed("home");
                },
              ),
            ],
          },
        ),
      ),
    );
  }
}
