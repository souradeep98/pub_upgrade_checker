import 'package:flutter/material.dart';
import 'package:pub_upgrade_checker/home.dart';

void main() {
  runApp(const PubUpgradeChecker());
}

class PubUpgradeChecker extends StatelessWidget {
  const PubUpgradeChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pub Upgrade Checker',
      home: Home(),
    );
  }
}
