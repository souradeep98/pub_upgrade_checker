part of widgets;

abstract class Blinking {
  bool hoverToStopBlinking = true;
  double _maxBlinkTime = double.infinity;

  AnimationController get _animationController;

  Future<void> startBlinking({
    bool hoverToStopBlinking = true,
    double maximumTimes = double.infinity,
  }) async {
    this.hoverToStopBlinking = hoverToStopBlinking;
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
}
