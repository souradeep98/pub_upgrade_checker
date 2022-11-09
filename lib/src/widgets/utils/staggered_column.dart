part of widgets;

List<Widget> childrenToStaggeredList({
  Duration? duration,
  Duration? delay,
  required Widget Function(Widget child) childAnimationBuilder,
  /// If the widget at the index should be in an Expanded widget, the flexFactor should be non-null, it should be null otherwise
  int? Function(int index)? expandedFlexFactor,
  required List<Widget> children,
}) =>
    children
        .asMap()
        .map((index, widget) {
          final Widget child = AnimationConfiguration.staggeredList(
            position: index,
            duration: duration ?? const Duration(milliseconds: 225),
            delay: delay,
            child: childAnimationBuilder(widget),
          );

          if (expandedFlexFactor == null) {
            return MapEntry(
              index,
              child,
            );
          }
          final int? flex = expandedFlexFactor(index);
          return MapEntry(
            index,
            flex != null
                ? Expanded(
                    flex: flex,
                    child: child,
                  )
                : child,
          );
        })
        .values
        .toList();
