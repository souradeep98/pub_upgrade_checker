part of widgets;

List<Widget> childrenToStaggeredList({
  Duration? duration,
  Duration? delay,
  required Widget Function(Widget child) childAnimationBuilder,
  Widget? Function(int index, Widget child)? wrapperBuilder,
  required List<Widget> children,
}) {
  var result = children
      .asMap()
      .map<int, Widget>((index, currentChild) {
        final Widget child = AnimationConfiguration.staggeredList(
          position: index,
          duration: duration ?? const Duration(milliseconds: 225),
          delay: delay,
          child: childAnimationBuilder(currentChild),
        );
        return MapEntry(
          index,
          child,
        );
      })
      .values
      .toList();

  if (wrapperBuilder != null) {
    result = result
        .asMap()
        .map<int, Widget>((index, currentChild) {
          final resultChild = wrapperBuilder(index, currentChild);

          return MapEntry<int, Widget>(
            index,
            resultChild ?? currentChild,
          );
        })
        .values
        .toList();
  }

  return result;
}
