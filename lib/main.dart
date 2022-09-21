import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_essentials/flutter_essentials.dart';
import 'package:pub_upgrade_checker/src/constants.dart';
import 'package:pub_upgrade_checker/src/pages.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  //debugRepaintRainbowEnabled = true;
  if (isDesktop) {
    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      minimumSize: Size(800, 600),
      //size: Size(1280, 720),
      //center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: "Pub Upgrade Checker",
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.show();
      await windowManager.focus();
    });

    /*await Window.initialize();

    doWhenWindowReady(() async {
      appWindow.minSize = const Size(
        640,
        400,
      );
      appWindow.title = "Pub Upgrade Checker";
      await Window.setEffect(effect: WindowEffect.transparent, dark: false);
      await Window.hideWindowControls();
      appWindow.show();
    });*/
  }
  runApp(const PubUpgradeChecker());
}

class PubUpgradeChecker extends StatefulWidget {
  const PubUpgradeChecker({super.key});

  @override
  State<PubUpgradeChecker> createState() => _PubUpgradeCheckerState();
}

class _PubUpgradeCheckerState extends State<PubUpgradeChecker>
    with WindowListener {
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
  void onWindowFocus() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget result = MaterialApp(
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      title: 'Pub Upgrade Checker',
      home: const Home(),
      theme: AppThemes.darkTheme,
    );

    if (isDesktop) {
      final BorderRadius borderRadius =
          BorderRadius.circular(Consts.appBorderRadius);
      result = Directionality(
        textDirection: TextDirection.ltr,
        child: DragToResizeArea(
          //resizeEdgeColor: Colors.red.withOpacity(0.3),
          resizeEdgeSize: 12,
          resizeEdgeMargin:
              const EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 15),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 20),
            child: Material(
              elevation: 10,
              color: Colors.transparent,
              type: MaterialType.card,
              borderRadius: borderRadius,
              child: ClipRRect(
                borderRadius: borderRadius,
                child: result,
              ),
            ),
          ),
        ),
      );
    }

    return result;
  }
}
