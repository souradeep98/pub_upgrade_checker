import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_essentials/flutter_essentials.dart';
import 'package:pub_upgrade_checker/src/pages.dart';

void main() {
  if (isDesktop) {
    WidgetsFlutterBinding.ensureInitialized();
    doWhenWindowReady(() {
      appWindow.minSize = const Size(
        640,
        400,
      );
      appWindow.title = "Pub Upgrade Checker";
    });
  }
  runApp(const PubUpgradeChecker());
}

class PubUpgradeChecker extends StatelessWidget {
  const PubUpgradeChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pub Upgrade Checker',
      home: const Home(),
      theme: ThemeData.light(),
    );
  }
}
