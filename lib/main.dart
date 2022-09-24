import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_essentials/flutter_essentials.dart';
import 'package:pub_upgrade_checker/src/constants.dart';
import 'package:pub_upgrade_checker/src/pages.dart';
import 'package:window_manager/window_manager.dart';

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
    Widget result = MaterialApp(
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      title: 'Pub Upgrade Checker',
      home: const Home(),
      theme: AppThemes.darkTheme,
    );

    if (isDesktop) {
      result = DesktopFrame(
        child: result,
      );
    }

    return result;
  }
}

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
}

class _DesktopFrameState extends State<DesktopFrame>
    with WindowListener, SingleTickerProviderStateMixin {
  // Vars
  late final AnimationController _animationController;
  final ValueNotifier<bool> _initialized = ValueNotifier<bool>(false);

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();

    //! Initiallize
    _animationController = AnimationController(vsync: this);

    _initialFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
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
        parent: _animationController,
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
        parent: _animationController,
        curve: const Interval(
          _logoFadeAnimationStart,
          _logoFadeAnimationEnd,
          curve: Curves.easeOutExpo,
        ),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.2,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
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
    _animationController
        .animateTo(
      1,
      duration: const Duration(
        seconds: 3,
      ),
    )
        .then((value) {
      _initialized.value = true;
      windowManager.setAlwaysOnTop(false).then((value) {
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _initialized.dispose();
    _animationController.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }

  @override
  void onWindowEvent(String event) {
    logExceptRelease("Window Event: $event");
  }

  //! Animations & Value getters
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _initialFadeAnimation;
  late final Animation<double> _scaleAnimation;

  ShapeBorder get _borderValue => ShapeBorderTween(
        begin: const CircleBorder(),
        end: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Consts.appBorderRadius),
        ),
      ).evaluate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(
            _clipAnimationStart,
            _clipAnimationEnd,
            //curve: Curves.easeOutExpo,
            curve: Curves.easeInBack,
          ),
        ),
      )!;

  Alignment get _alignmentValue => Tween<AlignmentGeometry>(
        begin: const Alignment(0, 0.8),
        end: Alignment.center,
      )
          .evaluate(
            CurvedAnimation(
              parent: _animationController,
              curve: const Interval(
                _alignAnimationStart,
                _alignAnimationEnd,
                curve: Curves.elasticOut,
                //curve: Cubic(0.35, 0.91, 0.74, 1.41),
              ),
            ),
          )
          .resolve(TextDirection.ltr);

  //! Animation Durations
  static const double _animationStart = 0;

  // initial reveal animation
  static const double _initialFadeAnimationStart = _animationStart;
  static const double _initialFadeAnimationEnd =
      _initialFadeAnimationStart + 0.15;

  // logo reveal animation
  static const double _logoAnimationStart = _animationStart;

  static const double _alignAnimationStart = _logoAnimationStart; //0
  static const double _alignAnimationEnd = _logoAnimationEnd + 0.35; //0.8;

  static const double _rotationAnimationStart = _logoAnimationStart; //0
  static const double _rotationAnimationEnd = _logoAnimationEnd; //0.45

  static const double _logoAnimationEnd = 0.45;

  // window reveal animation
  static const double _revealAnimationStart = 0.45;

  static const double _scaleAnimationStart = _revealAnimationStart;
  static const double _scaleAnimationEnd = _revealAnimationEnd - 0.4; //0.6;

  static const double _clipAnimationStart = _revealAnimationStart;
  static const double _clipAnimationEnd = _revealAnimationEnd - 0.4; //0.6;

  static const double _logoFadeAnimationStart =
      _revealAnimationStart + 0.25; //0.75;
  static const double _logoFadeAnimationEnd = _revealAnimationEnd;

  static const double _revealAnimationEnd = _animationEnd;

  static const double _animationEnd = 1;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<bool>(
        valueListenable: _initialized,
        builder: (context, initialized, child) {
          return AbsorbPointer(
            absorbing: !initialized,
            child: child,
          );
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            logExceptRelease("Scale Animation Value: ${_scaleAnimation.value}");
            return ScaleTransition(
              scale: _scaleAnimation,
              alignment: _alignmentValue,
              child: child,
            );
          },
          child: FadeTransition(
            opacity: _initialFadeAnimation,
            child: RotationTransition(
              turns: _rotationAnimation,
              child: DragToResizeArea(
                //resizeEdgeColor: Colors.red.withOpacity(0.3),
                resizeEdgeSize: 12,
                resizeEdgeMargin: const EdgeInsets.only(
                  left: 5,
                  right: 5,
                  top: 5,
                  bottom: 15,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 10,
                    bottom: 20,
                  ),
                  child: AnimatedBuilder(
                    //Clipper
                    animation: _animationController,
                    builder: (context, content) {
                      return PhysicalShape(
                        elevation: 10,
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        color: Colors.transparent,
                        clipper: ShapeBorderClipper(
                          shape: _borderValue,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          fit: StackFit.expand,
                          children: [
                            widget.child,
                            content!,
                          ],
                        ),
                      );
                    },
                    child: ValueListenableBuilder<bool>(
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*class _ScaleAnimationCustomCurve extends Curve {
  @override
  double transformInternal(double t) {
    // TODO: implement transformInternal
    return super.transformInternal(t);
  }
}*/

class _Border extends StatefulWidget {
  final Widget child;
  final Color? color;

  const _Border({
    // ignore: unused_element
    super.key,
    required this.child,
    // ignore: unused_element
    this.color,
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
          width: 3,
        ),
      ),
      position: DecorationPosition.foreground,
      child: widget.child,
    );
  }
}
