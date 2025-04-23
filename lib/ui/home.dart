import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:labshare/widgets/window_buttons.dart';
import 'package:window_manager/window_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
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

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: Text('LabShare'),
        leading: IconButton(icon: Icon(FluentIcons.back), onPressed: null),
        automaticallyImplyLeading: false,
        actions: WindowButtons(),
      ),
      content: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Hello, there!", style: TextStyle(fontSize: 40)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                context.pushReplacementNamed("teacher");
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  EdgeInsets.fromLTRB(20, 10, 20, 10),
                ),
              ),
              child: Text(
                "Faculty",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  EdgeInsets.fromLTRB(20, 10, 20, 10),
                ),
              ),
              onPressed: () {
                context.pushReplacementNamed("student");
              },

              child: Text(
                "Student",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
