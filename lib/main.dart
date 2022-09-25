import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pub_upgrade_checker/src/constants.dart';
import 'package:pub_upgrade_checker/src/pages.dart';
import 'package:pub_upgrade_checker/src/widgets.dart';

Future<void> main() async {
  //debugRepaintRainbowEnabled = true;
  Paint.enableDithering = true;
  await DesktopFrame.initialize();
  runApp(const PubUpgradeChecker());
}

class PubUpgradeChecker extends StatelessWidget {
  const PubUpgradeChecker({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget result = MaterialApp(
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      title: 'Pub Upgrade Checker',
      home: const AppFrame(),
      theme: AppThemes.darkTheme,
    );

    /*if (isDesktop) {
      result = DesktopFrame(
        child: result,
      );
    }*/

    return result;
  }
}
