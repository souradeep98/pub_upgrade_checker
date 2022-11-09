part of widgets;

class ItemView extends StatefulWidget {
  final UpdateInformation updateInformation;
  final void Function(ReleaseChannel channel) onUpdateChannelChange;

  const ItemView({
    super.key,
    required this.updateInformation,
    required this.onUpdateChannelChange,
  });

  @override
  State<ItemView> createState() => _ItemViewState();
}

class _ItemViewState extends State<ItemView> {
  // UI
  TextStyle? _getTextStyle(UpdateType updateType) {
    switch (updateType) {
      case UpdateType.update:
        return const TextStyle(fontWeight: FontWeight.w700);
      case UpdateType.majorUpdate:
        return const TextStyle(fontWeight: FontWeight.w700, color: Colors.red);
      case UpdateType.unknown:
        return const TextStyle(color: Colors.red);
      case UpdateType.noUpdate:
        return null;
      case UpdateType.higher:
        return const TextStyle(fontWeight: FontWeight.w600);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      waitDuration: const Duration(seconds: 1),
      message:
          widget.updateInformation.updateTypeOfCurrentChannel?.description ??
              "",
      child: SwitchListTile(
        key: ValueKey<UpdateInformation>(
          widget.updateInformation,
        ),
        dense: true,
        //title: Text(updateInformation.toString()),
        title: Text(
          widget.updateInformation.current.toString(),
        ),
        subtitle: Text(
          widget.updateInformation.updateDetails,
          style: _getTextStyle(
            widget.updateInformation.stableUpdateType,
          ),
          textScaleFactor: 0.9,
        ),
        value: widget.updateInformation.setToUpdate,
        onChanged: (widget.updateInformation.updateAvailableForAnyChannel)
            ? (shouldUpdate) {
                /*_setUpdateTo(
                      index,
                      shouldUpdate
                          ? ReleaseChannel.stable
                          : ReleaseChannel.none,
                    );*/
                widget.onUpdateChannelChange(
                  shouldUpdate ? ReleaseChannel.stable : ReleaseChannel.none,
                );
              }
            : null,
      ),
    );
  }
}
