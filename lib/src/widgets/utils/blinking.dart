part of widgets;

abstract class Blinking {
  bool hoverToStopBlinking = true;
  double _maxBlinkTime = double.infinity;

  AnimationController get _animationController;

  Future<void> startBlinking({
    bool hoverToStopBlinking = true,
    double maximumTimes = double.infinity,
    Curve forwardCurve = Curves.easeInOutCubic,
    Curve backwardCurve = Curves.easeOutSine,
    Duration? forwardDuration,
    Duration? backwardDuration,
  }) async {
    this.hoverToStopBlinking = hoverToStopBlinking;
    _maxBlinkTime = maximumTimes - 1;
    _animationController.reset();

    await Future.doWhile(() async {
      await _animationController.animateTo(
        1,
        curve: forwardCurve,
        duration: forwardDuration,
      );
      await _animationController.animateTo(
        0,
        curve: backwardCurve,
        duration: backwardDuration,
      );
      return (_maxBlinkTime--) > 0;
    });
  }

  void stopBlinking() {
    _maxBlinkTime = 0;
    _animationController.reset();
  }
}
