import 'package:fluent_ui/fluent_ui.dart';
import 'package:labshare/router.dart';
import 'package:system_theme/system_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp.router(
      title: "LabShare",
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: SystemTheme.accentColor.accent.toAccentColor(),
      ),
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: SystemTheme.accentColor.accent.toAccentColor(),
      ),
    );
  }
}
