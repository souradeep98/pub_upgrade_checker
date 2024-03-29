part of pages;

class AppFrame extends StatelessWidget {
  const AppFrame({super.key});

  @override
  Widget build(BuildContext context) {
    Widget content = const Scaffold(body:  Home());
    
    if (isDesktop)  {
      content = DesktopFrame(builder: (context) => const Scaffold(body: Home()),);
    }
    return content;
  }
}
