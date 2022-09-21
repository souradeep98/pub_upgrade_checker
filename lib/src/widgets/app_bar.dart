part of widgets;

class PUCAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PUCAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (x) {
        windowManager.startDragging();
      },
      child: ColoredBox(
        color: theme
                .extension<PUCAppBarThemeData>()
                ?.backgroundColor ??
            theme.primaryColor,
        child: SizedBox.fromSize(
          size: preferredSize,
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    if (isDesktop) {
      return const Size.fromHeight(20);
    }
    return AppBar().preferredSize;
  }
}
