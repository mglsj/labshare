import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:labshare/network/session.dart';
import 'package:labshare/widgets/window_buttons.dart';
import 'package:window_manager/window_manager.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

enum UiStage { initial, scanning, received, saved }

class _StudentScreenState extends State<StudentScreen> with WindowListener {
  Session? session;
  UiStage uiStage = UiStage.initial;

  @override
  void initState() {
    windowManager.addListener(this);
    session = Session.student();
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    session?.stop();
    super.dispose();
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
    return NavigationView(
      appBar: NavigationAppBar(
        title: Text('LabShare | Student'),
        leading: IconButton(
          icon: Icon(FluentIcons.back),
          onPressed: () {
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
            (UiStage.initial) => [
              FilledButton(
                onPressed: scan,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    EdgeInsets.fromLTRB(20, 10, 20, 10),
                  ),
                ),
                child: Text(
                  "Start scanning",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
                ),
              ),
            ],
            (UiStage.scanning) => [
              Text("Scanning for files..."),
              SizedBox(height: 10),
              ProgressBar(),
            ],
            (UiStage.received) => [
              Text("Saving File..."),
              SizedBox(height: 10),
              ProgressRing(),
            ],
            (UiStage.saved) => [
              Text("Transfer Completed, seeding to other peers"),
            ],
          },
        ),
      ),
    );
  }
}
