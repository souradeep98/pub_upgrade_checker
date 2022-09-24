part of widgets;

class FavouredButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const FavouredButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<FavouredButton> createState() => FavouredButtonState();
}

class FavouredButtonState extends State<FavouredButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _hoverToStopBlinking = true;
  double _maxBlinkTime = double.infinity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 800,
      ),
    );
    /*WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        Timer(
          const Duration(seconds: 5),
          () {
            startBlinking(maximumTimes: 5);
          },
        );
      },
    );*/
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> startBlinking({
    bool hoverToStopBlinking = true,
    double maximumTimes = double.infinity,
  }) async {
    _hoverToStopBlinking = hoverToStopBlinking;
    _maxBlinkTime = maximumTimes - 1;
    _animationController.reset();

    await Future.doWhile(() async {
      await _animationController.forward();
      await _animationController.reverse();
      return (_maxBlinkTime--) > 0;
    });
  }

  void stopBlinking() {
    _maxBlinkTime = 0;
    _animationController.reset();
  }

  final ColorTween _backgroundColorAnimation = ColorTween(
    begin: Colors.white10.withOpacity(0.1),
    end: Colors.white10.withOpacity(0.3),
  );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        if (_hoverToStopBlinking) {
          stopBlinking();
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ElevatedButton(
            child: Text(widget.text),
            onPressed: widget.onPressed,
            style: ButtonStyle(
              animationDuration: const Duration(milliseconds: 150),
              textStyle: const MaterialStatePropertyAll(
                TextStyle(
                  fontWeight: FontWeight.w400,
                ),
              ),
              /*MaterialStateProperty.resolveWith<TextStyle?>((states) {
                if (states.contains(MaterialState.hovered)) {
                  return const TextStyle(
                    fontWeight: FontWeight.w700,
                  );
                } else {
                  return const TextStyle(
                    fontWeight: FontWeight.w400,
                  );
                }
              }),*/
              foregroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.hovered)) {
                  return Colors.black;
                } else {
                  return Colors.white;
                }
              }),
              backgroundColor:
                  MaterialStateProperty.resolveWith<Color?>((states) {
                if (states.contains(MaterialState.hovered)) {
                  return Colors.white;
                } else {
                  return _backgroundColorAnimation
                      .evaluate(_animationController);
                }
              }),
              shape: const MaterialStatePropertyAll(StadiumBorder()),
              mouseCursor:
                  const MaterialStatePropertyAll(SystemMouseCursors.click),
              /*padding: const MaterialStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 30),
              ),*/
              minimumSize: const MaterialStatePropertyAll(Size(90, 36)),
              elevation: const MaterialStatePropertyAll(0),
            ),
          );
        },
      ),
    );
  }
}

class AlternateChoiceButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const AlternateChoiceButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<AlternateChoiceButton> createState() => AlternateChoiceButtonState();
}

class AlternateChoiceButtonState extends State<AlternateChoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _hoverToStopBlinking = true;
  double _maxBlinkTime = double.infinity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 800,
      ),
    );
    /*WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        Timer(
          const Duration(seconds: 5),
          startBlinking,
        );
      },
    );*/
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> startBlinking({
    bool hoverToStopBlinking = true,
    double maximumTimes = double.infinity,
  }) async {
    _hoverToStopBlinking = hoverToStopBlinking;
    _maxBlinkTime = maximumTimes - 1;
    _animationController.reset();

    await Future.doWhile(() async {
      await _animationController.forward();
      await _animationController.reverse();
      return (_maxBlinkTime--) > 0;
    });
  }

  void stopBlinking() {
    _maxBlinkTime = 0;
    _animationController.reset();
  }

  final ColorTween _colorTween = ColorTween(
    begin: Colors.white54,
    end: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        if (_hoverToStopBlinking) {
          stopBlinking();
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ElevatedButton(
            child: Text(widget.text),
            onPressed: widget.onPressed,
            style: ButtonStyle(
              animationDuration: const Duration(milliseconds: 250),
              textStyle: const MaterialStatePropertyAll(
                TextStyle(
                  fontWeight: FontWeight.w400,
                ),
              ),
              /*MaterialStateProperty.resolveWith<TextStyle?>((states) {
                if (states.contains(MaterialState.hovered)) {
                  return const TextStyle(
                    fontWeight: FontWeight.w700,
                  );
                } else {
                  return const TextStyle(
                    fontWeight: FontWeight.w400,
                  );
                }
              }),*/
              foregroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.hovered)) {
                  return Colors.white;
                } else {
                  return Colors.white54;
                }
              }),
              backgroundColor:
                  const MaterialStatePropertyAll(Colors.transparent),
              overlayColor: const MaterialStatePropertyAll(Colors.transparent),
              shape:
                  MaterialStateProperty.resolveWith<OutlinedBorder?>((states) {
                if (states.contains(MaterialState.hovered)) {
                  return const StadiumBorder(
                    side: BorderSide(
                      color: Colors.white,
                    ),
                  );
                }
                return StadiumBorder(
                  side: BorderSide(
                    color: _colorTween.evaluate(_animationController)!,
                  ),
                );
              }),
              mouseCursor:
                  const MaterialStatePropertyAll(SystemMouseCursors.click),
              minimumSize: const MaterialStatePropertyAll(Size(80, 36)),
              elevation: const MaterialStatePropertyAll(0),
            ),
          );
        },
      ),
    );
  }
}
