part of widgets;

const double _kDesktopWindowControlButtonIconSize = 14;

class CloseButton extends StatefulWidget {
  const CloseButton({super.key});

  @override
  State<CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<CloseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ElevatedButton(
            child: const Icon(
              Icons.close_rounded,
              size: _kDesktopWindowControlButtonIconSize,
            ),
            onPressed: windowManager.close,
            style: ButtonStyle(
              animationDuration: const Duration(milliseconds: 250),
              textStyle: const MaterialStatePropertyAll(
                TextStyle(
                  fontWeight: FontWeight.w400,
                ),
              ),
              foregroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.hovered)) {
                  return Colors.white;
                } else {
                  return Colors.white54;
                }
              }),
              backgroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.hovered)) {
                  return const Color.fromARGB(255, 255, 0, 0);
                } else {
                  return Colors.transparent;
                }
              }),
              overlayColor: const MaterialStatePropertyAll(Colors.transparent),
              surfaceTintColor:
                  const MaterialStatePropertyAll(Colors.transparent),
              shape: const MaterialStatePropertyAll(RoundedRectangleBorder()),
              elevation: const MaterialStatePropertyAll(0),
            ),
          );
        },
      ),
    );
  }
}

class MaximizeButton extends StatefulWidget {
  const MaximizeButton({
    super.key,
  });

  @override
  State<MaximizeButton> createState() => _MaximizeButtonState();
}

class _MaximizeButtonState extends State<MaximizeButton>
    with Blinking, TickerProviderStateMixin, WindowListener {
  @override
  late final AnimationController _animationController;

  late final AnimationController _windowAnimationController;

  late final ValueNotifier<bool> _isMaximized;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _windowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _isMaximized = ValueNotifier<bool>(false);
    _alignmentAnimation = _alignmentTween.animate(_windowAnimationController);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _isMaximized.dispose();
    _animationController.dispose();
    _windowAnimationController.dispose();
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    _isMaximized.value = true;
  }

  @override
  void onWindowUnmaximize() {
    _isMaximized.value = false;
  }

  final Tween<AlignmentGeometry> _alignmentTween = Tween<AlignmentGeometry>(
    begin: Alignment.center,
    end: Alignment.topRight,
  );

  late final Animation<AlignmentGeometry> _alignmentAnimation;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        if (hoverToStopBlinking) {
          stopBlinking();
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ElevatedButton(
            child: child,
            onPressed: () async {
              final bool isMaximized = _isMaximized.value;
              if (isMaximized) {
                await windowManager.unmaximize();
              } else {
                final bool isMaximizable = await windowManager.isMaximizable();
                if (isMaximizable) {
                  await windowManager.maximize();
                }
              }
            },
            style: ButtonStyle(
              animationDuration: const Duration(milliseconds: 250),
              textStyle: const MaterialStatePropertyAll(
                TextStyle(
                  fontWeight: FontWeight.w400,
                ),
              ),
              foregroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.hovered)) {
                  return Colors.white;
                } else {
                  return Colors.white54;
                }
              }),
              backgroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.hovered)) {
                  return Colors.white38.withOpacity(0.3);
                } else {
                  return Colors.transparent;
                }
              }),
              overlayColor: const MaterialStatePropertyAll(Colors.transparent),
              shape: const MaterialStatePropertyAll(RoundedRectangleBorder()),
              elevation: const MaterialStatePropertyAll(0),
            ),
          );
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: _isMaximized,
          builder: (context, isMaximized, _) {
            return SizedBox(
              width: 20,
              height: 20,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  AlignTransition(
                    alignment: _alignmentAnimation,
                    child: const Icon(
                      Icons.rectangle_outlined,
                      size: _kDesktopWindowControlButtonIconSize,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: AnimatedShowHide(
                      showDuration: const Duration(milliseconds: 200),
                      hideDuration: const Duration(milliseconds: 200),
                      isShown: isMaximized,
                      child: const Icon(
                        Icons.rectangle_outlined,
                        size: _kDesktopWindowControlButtonIconSize,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class MinimizeButton extends StatefulWidget {
  const MinimizeButton({super.key});

  @override
  State<MinimizeButton> createState() => _MinimizeButtonState();
}

class _MinimizeButtonState extends State<MinimizeButton>
    with Blinking, SingleTickerProviderStateMixin, WindowListener {
  @override
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        if (hoverToStopBlinking) {
          stopBlinking();
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ElevatedButton(
            child: const Icon(
              Icons.minimize_sharp,
              size: _kDesktopWindowControlButtonIconSize,
            ),
            onPressed: () async {
              final bool isMinimizable = await windowManager.isMinimizable();
              if (isMinimizable) {
                await windowManager.minimize();
              }
            },
            style: ButtonStyle(
              animationDuration: const Duration(milliseconds: 250),
              textStyle: const MaterialStatePropertyAll(
                TextStyle(
                  fontWeight: FontWeight.w400,
                ),
              ),
              foregroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.hovered)) {
                  return Colors.white;
                } else {
                  return Colors.white54;
                }
              }),
              backgroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.hovered)) {
                  return Colors.white38.withOpacity(0.3);
                } else {
                  return Colors.transparent;
                }
              }),
              overlayColor: const MaterialStatePropertyAll(Colors.transparent),
              shape: const MaterialStatePropertyAll(RoundedRectangleBorder()),
              elevation: const MaterialStatePropertyAll(0),
            ),
          );
        },
      ),
    );
  }
}
