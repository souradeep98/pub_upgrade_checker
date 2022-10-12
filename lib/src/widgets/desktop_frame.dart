part of widgets;

class DesktopFrame extends StatefulWidget {
  final Widget child;

  const DesktopFrame({
    super.key,
    required this.child,
  });

  static Future<bool> initialize() async {
    if (!isDesktop) {
      return false;
    }

    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      minimumSize: Size(800, 600),
      //size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: "Pub Upgrade Checker",
      alwaysOnTop: true,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.show();
      await windowManager.focus();
    });

    return true;
  }

  @override
  State<DesktopFrame> createState() => _DesktopFrameState();

  static const Duration initialAnimationDuration = Duration(
    seconds: 3,
  );
}

class _DesktopFrameState extends State<DesktopFrame>
    with WindowListener, TickerProviderStateMixin {
  TextDirection? _textDirection;
  // Vars
  late final AnimationController _initialAnimationController;
  late final AnimationController _windowAnimationController;
  late final ValueNotifier<bool> _initialized;
  //late final ValueNotifier<bool> _isMaximized;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initialized = ValueNotifier<bool>(false);
    //_isMaximized = ValueNotifier<bool>(false);

    //! Initiallize
    _initialAnimationController = AnimationController(vsync: this);
    _windowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _initialFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _initialAnimationController,
        curve: const Interval(
          _initialFadeAnimationStart,
          _initialFadeAnimationEnd,
          curve: Curves.easeIn,
        ),
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: -0.6,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _initialAnimationController,
        curve: const Interval(
          _rotationAnimationStart,
          _rotationAnimationEnd,
          curve: Curves.easeOutExpo,
        ),
      ),
    );

    _logoFadeAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _initialAnimationController,
        curve: const Interval(
          _logoFadeAnimationStart,
          _logoFadeAnimationEnd,
          curve: Curves.easeOutExpo,
        ),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.18,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _initialAnimationController,
        curve: const Interval(
          _scaleAnimationStart,
          _scaleAnimationEnd,
          curve: Curves.easeInBack,
          //curve: Curves.easeOutExpo,
        ),
      ),
    );

    //! Start Animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimation();
    });
  }

  void _startAnimation() {
    _initialAnimationController
        .animateTo(
      1,
      duration: DesktopFrame.initialAnimationDuration,
    )
        .then((value) {
      _initialized.value = true;
      windowManager.setAlwaysOnTop(false);
    });
  }

  @override
  void dispose() {
    //_isMaximized.dispose();
    _initialized.dispose();
    _initialAnimationController.dispose();
    _windowAnimationController.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }

  /*@override
  void onWindowEvent(String event) {
    logExceptRelease("Window Event: $event");
  }*/

  @override
  void onWindowMaximize() {
    _windowAnimationController.forward();
  }

  @override
  void onWindowUnmaximize() {
    _windowAnimationController.reverse();
  }

  //! Animations & Value getters
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _initialFadeAnimation;
  late final Animation<double> _scaleAnimation;

  final ShapeBorderTween _initialShapeBorderTween = ShapeBorderTween(
    begin: const CircleBorder(),
    end: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Consts.appBorderRadius),
    ),
  );

  ShapeBorder get _initialBorderValue => _initialShapeBorderTween.evaluate(
        CurvedAnimation(
          parent: _initialAnimationController,
          curve: const Interval(
            _clipAnimationStart,
            _clipAnimationEnd,
            //curve: Curves.easeOutExpo,
            curve: Curves.easeInBack,
          ),
        ),
      )!;

  final Tween<AlignmentGeometry> _alignmentGeometryTween =
      Tween<AlignmentGeometry>(
    begin: const Alignment(0, 0.8),
    end: Alignment.center,
  );

  Alignment get _alignmentValue => _alignmentGeometryTween
      .evaluate(
        CurvedAnimation(
          parent: _initialAnimationController,
          curve: const Interval(
            _alignAnimationStart,
            _alignAnimationEnd,
            curve: Curves.elasticOut,
          ),
        ),
      )
      .resolve(
        _textDirection ??= Directionality.of(context),
      );

  final EdgeInsetsTween _paddingTween = EdgeInsetsTween(
    begin: const EdgeInsets.only(
      left: 10,
      right: 10,
      top: 10,
      bottom: 20,
    ),
    end: EdgeInsets.zero,
  );

  EdgeInsets get _paddingValue => _paddingTween.evaluate(
        CurvedAnimation(
          parent: _windowAnimationController,
          curve: Curves.linear,
        ),
      );

  final ShapeBorderTween _shapeBorderTweenAfterInit = ShapeBorderTween(
    begin: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Consts.appBorderRadius),
      side: const BorderSide(color: Colors.white),
    ),
    end: const RoundedRectangleBorder(
      side: BorderSide(color: Colors.white),
    ),
  );

  ShapeBorder get _borderValueAfterInitialization =>
      _shapeBorderTweenAfterInit.evaluate(
        CurvedAnimation(
          parent: _windowAnimationController,
          curve: Curves.linear,
        ),
      )!;

  //! Animation Durations
  static const double _animationStart = 0;

  // initial reveal animation
  static const double _initialFadeAnimationStart = _animationStart;
  static const double _initialFadeAnimationEnd =
      _initialFadeAnimationStart + 0.20;

  // logo reveal animation
  static const double _logoAnimationStart = _animationStart;

  static const double _alignAnimationStart = _logoAnimationStart; //0
  static const double _alignAnimationEnd = _logoAnimationEnd + 0.45; //9;

  static const double _rotationAnimationStart = _logoAnimationStart; //0
  static const double _rotationAnimationEnd = _logoAnimationEnd; //0.45

  static const double _logoAnimationEnd = 0.45;

  // window reveal animation
  static const double _revealAnimationStart = 0.45;

  static const double _scaleAndClipAnimationStartOffset = -0.05; //0.40
  static const double _scaleAndClipAnimationEndOffset = -0.4; //0.6

  static const double _scaleAnimationStart =
      _revealAnimationStart + _scaleAndClipAnimationStartOffset;
  static const double _scaleAnimationEnd =
      _revealAnimationEnd + _scaleAndClipAnimationEndOffset;

  static const double _clipAnimationStart =
      _revealAnimationStart + _scaleAndClipAnimationStartOffset;
  static const double _clipAnimationEnd =
      _revealAnimationEnd + _scaleAndClipAnimationEndOffset;

  static const double _logoFadeAnimationStart =
      _revealAnimationStart + 0.25; //0.75;
  static const double _logoFadeAnimationEnd = _revealAnimationEnd;

  static const double _revealAnimationEnd = _animationEnd;

  static const double _animationEnd = 1;

  @override
  Widget build(BuildContext context) {
    final Widget appContent = _Frame(
      edges: const EdgeInsets.only(
        //top: 2,
        left: 4,
        right: 4,
        bottom: 4,
      ),
      titleBarHeight: 20,
      child: PhysicalShape(
        clipper: ShapeBorderClipper(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Consts.appBorderRadius),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        color: Colors.transparent,
        child: widget.child,
      ),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: _initialized,
      builder: (context, initialized, child) {
        return AbsorbPointer(
          absorbing: !initialized,
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _initialAnimationController,
        builder: (context, child) {
          //logExceptRelease("Scale Animation Value: ${_scaleAnimation.value}");
          return ScaleTransition(
            scale: _scaleAnimation,
            alignment: _alignmentValue,
            child: child,
          );
        },
        child: AnimatedBuilder(
          animation: _windowAnimationController,
          builder: (context, child) {
            //logExceptRelease("Padding Value: $_paddingValue");
            return Padding(
              padding: _paddingValue,
              child: child,
            );
          },
          child: FadeTransition(
            opacity: _initialFadeAnimation,
            child: RotationTransition(
              turns: _rotationAnimation,
              child: ValueListenableBuilder<bool>(
                valueListenable: _initialized,
                builder: (context, isInitialized, cchild) {
                  return AnimatedBuilder(
                    //Clipper
                    animation: isInitialized
                        ? _windowAnimationController
                        : _initialAnimationController,
                    builder: (context, logoImage) {
                      return PhysicalShape(
                        elevation: 10,
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        color: Colors.transparent,
                        clipper: ShapeBorderClipper(
                          shape: isInitialized
                              ? _borderValueAfterInitialization
                              : _initialBorderValue,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          fit: StackFit.expand,
                          children: [
                            appContent,
                            logoImage!,
                          ],
                        ),
                      );
                    },
                    child: ValueListenableBuilder<bool>(
                      // Logo Image
                      valueListenable: _initialized,
                      builder: (context, value, child) => IgnorePointer(
                        ignoring: value,
                        child: child,
                      ),
                      child: FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Image.asset(
                          "assets/pexels-benjamin-suter-3617500.jpg",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Frame extends StatefulWidget {
  //final AnimationController animationController;
  final Widget child;

  ///Edges for the content
  final EdgeInsetsGeometry? edges;
  final double? titleBarHeight;

  const _Frame({
    // ignore: unused_element
    super.key,
    required this.child,
    // ignore: unused_element
    this.edges,
    // ignore: unused_element
    this.titleBarHeight,
  });

  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame>
    with SingleTickerProviderStateMixin, WindowListener {
  TextDirection? _textDirection;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _animationController.dispose();
    super.dispose();
  }

  /*final ShapeBorderTween _shapeBorderTweenAfterInit = ShapeBorderTween(
    begin: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Consts.appBorderRadius),
      side: const BorderSide(color: Colors.white),
    ),
    end: const RoundedRectangleBorder(
      side: BorderSide(color: Colors.white),
    ),
  );

  ShapeBorder get _borderValueAfterInitialization =>
      _shapeBorderTweenAfterInit.evaluate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.linear,
        ),
      )!;*/

  /*@override
  void onWindowMaximize() {
    _animationController.forward();
  }

  @override
  void onWindowUnmaximize() {
    _animationController.reverse();
  }*/

  @override
  Widget build(BuildContext context) {
    const double minI = 2;
    final EdgeInsetsGeometry edges = widget.edges ??
        const EdgeInsets.only(
          //top: 3,
          left: 3,
          right: 3,
          bottom: 3,
        );
    final double titleBarHeight = widget.titleBarHeight ?? 16;

    //assert(titleBarHeight >= minI, "Must be greater than $minI");

    final EdgeInsets insets = edges.resolve(
      _textDirection ??= Directionality.of(context),
    );

    assert(
      [
        titleBarHeight,
        insets.left,
        insets.right,
        insets.bottom,
      ].every((element) => element >= minI),
      "Must be greater than $minI",
    );

    return PhysicalModel(
      color: const Color.fromARGB(
        255,
        23,
        22,
        28,
      ),
      child: Stack(
        children: [
          // Resize layer
          Column(
            children: [
              // Top
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ResizeElement(
                    resizeEdge: ResizeEdge.topLeft,
                    height: Consts.appBorderRadius,
                    width: Consts.appBorderRadius,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ResizeElement(
                              resizeEdge: ResizeEdge.top,
                              height: minI,
                              width: constraints.maxWidth,
                            ),
                            _Dragger(
                              height: titleBarHeight - minI,
                              width: constraints.maxWidth,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const _ResizeElement(
                    resizeEdge: ResizeEdge.topRight,
                    height: Consts.appBorderRadius,
                    width: Consts.appBorderRadius,
                  ),
                ],
              ),

              // Middle
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ResizeElement(
                          resizeEdge: ResizeEdge.left,
                          width: max(insets.left, minI),
                          height: constraints.maxHeight,
                        ),
                        _ResizeElement(
                          resizeEdge: ResizeEdge.right,
                          width: max(insets.left, minI),
                          height: constraints.maxHeight,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const _ResizeElement(
                    resizeEdge: ResizeEdge.bottomLeft,
                    height: Consts.appBorderRadius,
                    width: Consts.appBorderRadius,
                  ),
                  Expanded(
                    child: _ResizeElement(
                      resizeEdge: ResizeEdge.bottom,
                      height: max(insets.bottom, minI),
                    ),
                  ),
                  const _ResizeElement(
                    resizeEdge: ResizeEdge.bottomRight,
                    height: Consts.appBorderRadius,
                    width: Consts.appBorderRadius,
                  ),
                ],
              ),
            ],
          ),

          // Content
          Column(
            children: [
              SizedBox(
                height: titleBarHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    MinimizeButton(),
                    MaximizeButton(),
                    CloseButton(),
                    SizedBox(
                      width: 16,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: edges,
                  child: widget.child,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on ResizeEdge {
  MouseCursor get mouseCursor {
    switch (this) {
      case ResizeEdge.top:
        return SystemMouseCursors.resizeUp;
      case ResizeEdge.left:
        return SystemMouseCursors.resizeLeft;
      case ResizeEdge.right:
        return SystemMouseCursors.resizeRight;
      case ResizeEdge.bottom:
        return SystemMouseCursors.resizeDown;
      case ResizeEdge.topLeft:
        return SystemMouseCursors.resizeUpLeft;
      case ResizeEdge.bottomLeft:
        return SystemMouseCursors.resizeDownLeft;
      case ResizeEdge.topRight:
        return SystemMouseCursors.resizeUpRight;
      case ResizeEdge.bottomRight:
        return SystemMouseCursors.resizeDownRight;
    }
  }
}

class _ResizeElement extends StatelessWidget {
  final double? width;
  final double? height;
  final ResizeEdge resizeEdge;

  const _ResizeElement({
    // ignore: unused_element
    super.key,
    // ignore: unused_element
    this.width,
    // ignore: unused_element
    this.height,
    required this.resizeEdge,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: resizeEdge.mouseCursor,
      child: GestureDetector(
        onTapDown: (_) {
          windowManager.startResizing(resizeEdge);
        },
        child: SizedBox(
          height: height,
          width: width,
          child: const ColoredBox(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _Dragger extends StatefulWidget {
  final double? height;
  final double? width;

  const _Dragger({
    // ignore: unused_element
    super.key,
    // ignore: unused_element
    this.height,
    // ignore: unused_element
    this.width,
  });

  @override
  State<_Dragger> createState() => _DraggerState();
}

class _DraggerState extends State<_Dragger> {
  late final ValueNotifier<bool> _isGrabbing;

  @override
  void initState() {
    super.initState();
    _isGrabbing = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isGrabbing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isGrabbing,
      builder: (context, isGrabbing, child) {
        return MouseRegion(
          cursor: isGrabbing
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          _isGrabbing.value = true;
          windowManager.startDragging();
        },
        onTapUp: (_) {
          _isGrabbing.value = false;
        },
        child: SizedBox(
          height: widget.height,
          width: widget.width,
          child: const ColoredBox(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _Border extends StatefulWidget {
  final Widget child;
  final Color? color;
  final double? width;

  const _Border({
    // ignore: unused_element
    super.key,
    required this.child,
    // ignore: unused_element
    this.color,
    // ignore: unused_element
    this.width,
  });

  @override
  State<_Border> createState() => _BorderState();
}

class _BorderState extends State<_Border> {
  late Color _color;
  @override
  void initState() {
    super.initState();
    _color = widget.color ?? randomColor();
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return widget.child;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: _color,
          width: widget.width ?? 3,
        ),
      ),
      position: DecorationPosition.foreground,
      child: widget.child,
    );
  }
}
