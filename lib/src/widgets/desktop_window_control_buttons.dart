part of widgets;

class CloseButton extends StatelessWidget {
  const CloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _ControlButtonInternal(
      iconData: Icons.close,
      onClick: windowManager.close,
      hoverBackgroundColor: const Color.fromARGB(255, 255, 0, 0),
    );
  }
}

class MaximizeButton extends StatefulWidget {
  const MaximizeButton({super.key});

  @override
  State<MaximizeButton> createState() => _MaximizeButtonState();
}

class _MaximizeButtonState extends State<MaximizeButton> with WindowListener {
  //late final ValueNotifier<bool> _isMaximized;
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    //_isMaximized = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    //_isMaximized.dispose();
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(
      () {
        _isMaximized = true;
      },
    );
  }

  @override
  void onWindowUnmaximize() {
    setState(
      () {
        _isMaximized = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ControlButtonInternal(
      iconData:
          _isMaximized ? Icons.reset_tv_rounded : Icons.rectangle_outlined,
      onClick: () async {
        if (_isMaximized) {
          windowManager.unmaximize();
        } else if (await windowManager.isMaximizable()) {
          windowManager.maximize();
        }
      },
    );
  }
}

class MinimizeButton extends StatelessWidget {
  const MinimizeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _ControlButtonInternal(
      iconData: Icons.minimize_sharp,
      onClick: () async {
        final bool isMinimizable = await windowManager.isMinimizable();
        if (isMinimizable) {
          await windowManager.minimize();
        }
      },
    );
  }
}

class _ControlButtonInternal extends ButtonStyleButton {
  final IconData iconData;
  final VoidCallback? onClick;
  final Color? hoverBackgroundColor;

  _ControlButtonInternal({
    required this.iconData,
    required this.onClick,
    this.hoverBackgroundColor,
    // ignore: unused_element
    super.focusNode,
    // ignore: unused_element
    super.autofocus = false,
    // ignore: unused_element
    super.clipBehavior = Clip.none,
  }) : super(
          onPressed: onClick,
          onLongPress: null,
          onFocusChange: null,
          onHover: null,
          style: null,
          child: Icon(iconData, size: 16),
        );

  @override
  ButtonStyle defaultStyleOf(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ButtonStyle(
      shadowColor: MaterialStatePropertyAll(theme.shadowColor),
      visualDensity: theme.visualDensity,
      animationDuration: const Duration(milliseconds: 250),
      textStyle: const MaterialStatePropertyAll(
        TextStyle(
          fontWeight: FontWeight.w400,
        ),
      ),
      foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.hovered)) {
          return Colors.white;
        } else {
          return Colors.white54;
        }
      }),
      backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.hovered)) {
          return hoverBackgroundColor ?? Colors.white38.withOpacity(0.3);
        } else {
          return Colors.transparent;
        }
      }),
      overlayColor: const MaterialStatePropertyAll(Colors.transparent),
      surfaceTintColor: const MaterialStatePropertyAll(Colors.transparent),
      shape: const MaterialStatePropertyAll(RoundedRectangleBorder()),
      elevation: const MaterialStatePropertyAll(0),
      minimumSize: const MaterialStatePropertyAll(Size(30, 30)),
      maximumSize: const MaterialStatePropertyAll(Size.infinite),
      padding: const MaterialStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      ),
      alignment: Alignment.center,
      tapTargetSize: theme.materialTapTargetSize,
      enableFeedback: true,
      splashFactory: InkRipple.splashFactory,
      mouseCursor: const MaterialStatePropertyAll(SystemMouseCursors.basic),
    );
  }

  @override
  ButtonStyle? themeStyleOf(BuildContext context) {
    return null;
  }
}
