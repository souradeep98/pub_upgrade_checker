part of widgets;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late ValueNotifier<File?> _selectedFile;

  @override
  void initState() {
    super.initState();
    _selectedFile = ValueNotifier<File?>(null);
    //_test();
  }

  @override
  void dispose() {
    _selectedFile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: ValueListenableBuilder<File?>(
        valueListenable: _selectedFile,
        builder: (context, file, pickFile) {
          return PageTransitionSwitcher(
            duration: const Duration(seconds: 1),
            reverse: file == null,
            transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
              /*logExceptRelease(
                "PrimaryAnimation: ${primaryAnimation.value}\nSecondaryAnimation: ${secondaryAnimation.value}",
              );*/
              return SharedAxisTransition(
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.horizontal,
                child: child,
              );
            },
            child: file == null
                ? pickFile
                : _DependencyReviewer(
                    file: file,
                    onCloseFile: () {
                      _selectedFile.value = null;
                    },
                    onPickAnotherFile: (x) {
                      _selectedFile.value = x;
                    },
                  ),
          );
          /*if (file == null) {
            return pickFile!;
          }
          return DependencyReviewer(
            file: file,
            onCloseFile: () {
              _selectedFile.value = null;
            },
            onPickAnotherFile: (x) {
              _selectedFile.value = x;
            },
          );*/
        },
        child: _PickFile(
          onPick: (x) {
            _selectedFile.value = x;
          },
        ),
      ),
    );
  }
}

Future<void> _pickFile(void Function(File) onPick) async {
  final FilePickerResult? result = isSmartPhone
      ? (await FilePicker.platform.pickFiles())
      : (await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ["yaml"],
        ));

  if (result == null) {
    return;
  }
  logExceptRelease("Picked file: ${result.files.single.path}");
  onPick(File(result.files.single.path!));
}

class _PickFile extends StatefulWidget {
  final void Function(File) onPick;

  const _PickFile({
    // ignore: unused_element
    super.key,
    required this.onPick,
  });

  @override
  State<_PickFile> createState() => _PickFileState();
}

class _PickFileState extends State<_PickFile> {
  final GlobalKey<FavouredButtonState> _favouredButtonKey =
      GlobalKey<FavouredButtonState>();

  static const Duration _staggerDuration = Duration(milliseconds: 750);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      //_favouredButtonKey.currentState?.startBlinking();
      Timer(_staggerDuration * 3, () {
        _favouredButtonKey.currentState?.startBlinking();
      });
    });
  }

  bool _firstElement = true;

  Duration _getDelay() {
    //logger.d("_getDelay Called");
    const Duration base = Duration(milliseconds: 120);
    if (_firstElement) {
      _firstElement = false;
      return DesktopFrame.initialAnimationDuration + base;
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: _staggerDuration,
              childAnimationBuilder: (child) {
                final Duration delay = _getDelay();
                return SlideAnimation(
                  delay: delay,
                  duration: _staggerDuration,
                  verticalOffset: 10,
                  child: FadeInAnimation(
                    duration: _staggerDuration,
                    delay: delay,
                    child: child,
                  ),
                );
              },
              children: [
                empty,
                const Text("Pick your pubspec.yaml file"),
                const SizedBox(
                  height: 30,
                ),
                FavouredButton(
                  key: _favouredButtonKey,
                  onPressed: () async {
                    await _pickFile(widget.onPick);
                  },
                  text: "Pick",
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DependencyReviewer extends StatefulWidget {
  final VoidCallback onCloseFile;
  final void Function(File) onPickAnotherFile;
  final File file;

  const _DependencyReviewer({
    // ignore: unused_element
    super.key,
    required this.file,
    required this.onCloseFile,
    required this.onPickAnotherFile,
  });

  @override
  State<_DependencyReviewer> createState() => _DependencyReviewerState();
}

class _DependencyReviewerState extends State<_DependencyReviewer> {
  static const String _dependenciesTag = "dependencies";

  late SingleGenerateObservable<RxList<UpdateInformation>> _dependencies;
  ValueNotifier<String?>? _workStatusMessage;
  ValueNotifier<bool>? _showDifferencesOnly;
  TextEditingController? _textEditingController;
  ValueNotifier<int?>? _shownItems;
  final _CountsCache _countsCache = _CountsCache.zero();

  final List<CancelableOperation<dynamic>> _pendingOperations = [];
  CancelableOperation<dynamic> _addToOperations(Future Function() operation) {
    final CancelableOperation<dynamic> cancellableOperation =
        CancelableOperation<dynamic>.fromFuture(operation());
    _pendingOperations.add(cancellableOperation);

    cancellableOperation.valueOrCancellation("Cancelled").then((value) {
      if (value == "Cancelled") {
        logExceptRelease("Operation is cancelled, removing from pending");
      } else {
        logExceptRelease("Operation is completed, removing from pending");
        _pendingOperations.remove(cancellableOperation);
      }
    });

    return cancellableOperation;
  }

  @override
  void initState() {
    super.initState();
    _initiate();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _DependencyReviewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _disposeControllers(initiate: true);
    }
  }

  void _initiate() {
    _textEditingController = TextEditingController();
    _showDifferencesOnly = ValueNotifier<bool>(false);
    _workStatusMessage = ValueNotifier<String?>(null);
    _shownItems = ValueNotifier<int?>(null);

    _dependencies =
        Get.put<SingleGenerateObservable<RxList<UpdateInformation>>>(
      SingleGenerateObservable<RxList<UpdateInformation>>(
        dataGenerator: (data) async {
          final List<UpdateInformation> dependencies = await getDependencies(
            widget.file,
            workStatusMessage: _workStatusMessage,
            wsmDepth: WSMDepth.medium,
          );
          // Counts
          //_countsCache.total = dependencies.length;
          _countsCache.setCountsCache(
            dependencies: dependencies,
          );

          return RxList<UpdateInformation>(dependencies);
        },
        generateOnInit: false,
        allowModification: true,
      ),
      tag: _dependenciesTag,
    );
    _generate();
  }

  void _disposeControllers({bool initiate = false}) {
    _countsCache.clear();
    logExceptRelease(
      "Cancelling operation, pending operations: ${_pendingOperations.length}",
    );
    Future.wait(_pendingOperations.map((e) => e.cancel())).then((value) {
      _pendingOperations.clear();
    });
    operationContinue = false;
    logExceptRelease("Pending Operations cancelled");
    _shownItems?.dispose();
    _shownItems = null;
    _textEditingController?.dispose();
    _textEditingController = null;
    _workStatusMessage?.dispose();
    _workStatusMessage = null;
    _showDifferencesOnly?.dispose();
    _showDifferencesOnly = null;
    //_dependencyToTypeMap = null;
    logExceptRelease("Controllers Disposed");
    Future.wait([
      Get.delete<
          SingleGenerateObservable<RxMap<Dependency, UpdateInformation>>>(
        tag: _dependenciesTag,
      ),
    ]).then((value) {
      logExceptRelease("GetX controllers Disposed");
      if (initiate) {
        _initiate();
      }
    });
  }

  void _generate() {
    _addToOperations(() async {
      operationContinue = true;
      //await _dependencies.generate();
      await _dependencies.generate();
      await _getUpdates();
      operationContinue = false;
    });
  }

  Future<bool> _getUpdates() async {
    logExceptRelease("Getting updates");
    final List<UpdateInformation>? dependencies = _dependencies.data;
    if (dependencies == null) {
      return false;
    }
    final List<UpdateInformation> result = await getUpdates(
      dependencies,
      workStatusMessage: _workStatusMessage,
      wsmDepth: WSMDepth.medium,
    );

    logExceptRelease("Got update values");
    // Generate counts cache
    _countsCache.setCountsCache(
      //refresh: true,
      dependencies: result,
    );
    logExceptRelease("Setting updates");
    _dependencies.data = RxList<UpdateInformation>(result);
    hideStatusMessage(_workStatusMessage);
    return true;
  }

  Future<bool> _update() async {
    final List<UpdateInformation>? dependencies = _dependencies.data?.toList();
    if (dependencies == null) {
      return false;
    }
    operationContinue = true;
    await updateDependencies(
      file: widget.file,
      updateInformations: dependencies,
      workStatusMessage: _workStatusMessage,
      wsmDepth: WSMDepth.medium,
    );
    operationContinue = false;
    await _replaceCurrentDependenciesWithUpdates();
    return true;
  }

  Future<void> _replaceCurrentDependenciesWithUpdates() async {
    final List<UpdateInformation>? dependencies = _dependencies.data?.toList();
    if (dependencies == null) {
      return;
    }

    final List<UpdateInformation> updatedDependencies =
        dependencies.map<UpdateInformation>((e) => e.updatedVersion()).toList();

    _countsCache.setCountsCache(
      //refresh: true,
      dependencies: updatedDependencies,
    );

    _dependencies.data = RxList<UpdateInformation>(updatedDependencies);
  }

  void _setUpdateTo(int index, ReleaseChannel updateTo) {
    if (_dependencies.data == null) {
      return;
    }

    final UpdateInformation updateInformation = _dependencies.data![index];

    final UpdateInformation newUpdateInformation = updateInformation.copyWith(
      updateTo: updateTo,
    );

    // count cache
    _countsCache.modifyCountCacheForSingleChannelChange(
      oldDependency: updateInformation,
      newDependency: newUpdateInformation,
    );

    _dependencies.data![index] = newUpdateInformation;
  }

  //! Update All
  void _setUpdateToAll(bool shouldUpdate) {
    if (_dependencies.data == null) {
      return;
    }

    final List<UpdateInformation> updatedList = _dependencies.data!
        .map<UpdateInformation>(
          (element) => element.shouldUpdate(shouldUpdate),
        )
        .toList();

    // counts cache
    _countsCache.setCountsCache(dependencies: updatedList);

    _dependencies.data = RxList<UpdateInformation>(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    logExceptRelease("_DependencyReviewerState Build is running");
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color headerTextColor =
        primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Column(
      children: childrenToStaggeredList(
        delay: const Duration(milliseconds: 80),
        duration: const Duration(milliseconds: 350),
        childAnimationBuilder: (child) => SlideAnimation(
          verticalOffset: 10,
          child: FadeInAnimation(child: child),
        ),
        wrapperBuilder: (index, child) {
          if (index == 4) {
            return Expanded(
              child: child,
            );
          }
          return null;
        },
        children: [
          //! Opned File
          Tooltip(
            message: "Pick another file",
            child: ListTile(
              title: const Text("Opened File:"),
              subtitle: Text(widget.file.path),
              trailing: Tooltip(
                message: "Close File",
                child: IconButton(
                  onPressed: widget.onCloseFile,
                  icon: const Icon(Icons.close),
                ),
              ),
              onTap: () {
                _pickFile(widget.onPickAnotherFile);
              },
            ),
          ),
          const Divider(
            height: 1,
          ),

          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Obx(() {
                    if (_dependencies.data == null) {
                      return empty;
                    }
                    final int total = _countsCache.total;
                    return ValueListenableBuilder<int?>(
                      valueListenable: _shownItems!,
                      builder: (context, shownItems, _) {
                        return SearchField(
                          controller: _textEditingController!,
                          helperText: "Total: $total, Showing: $shownItems",
                        );
                      },
                    );
                  }),
                ),

                const VerticalDivider(
                  width: 1,
                  thickness: 0.5,
                  indent: 10,
                  endIndent: 10,
                ),

                //! Show unmatched only
                Expanded(
                  child: Obx(
                    () {
                      final bool notEligible =
                          _dependencies.data == null || _dependencies.isLoading;
                      return ValueListenableBuilder<bool>(
                        valueListenable: _showDifferencesOnly!,
                        builder: (context, value, _) {
                          return CheckboxListTile(
                            dense: true,
                            title: const Text(
                              "Show unmatched only",
                            ),
                            value: value,
                            onChanged: notEligible
                                ? null
                                : (x) {
                                    _showDifferencesOnly!.value = x ?? false;
                                  },
                          );
                        },
                      );
                    },
                  ),
                ),

                const VerticalDivider(
                  width: 1,
                  thickness: 0.5,
                  indent: 10,
                  endIndent: 10,
                ),

                //! Update all
                Expanded(
                  child: Obx(
                    () {
                      final bool gotItems = !_dependencies.hasNoData;
                      final int total = _countsCache.unmatched;

                      final int toUpdate = _countsCache.toUpdate;

                      final bool ifUpdateAll =
                          (total != 0) && (total == toUpdate);

                      return SwitchListTile(
                        dense: true,
                        title: Row(
                          children: [
                            const Expanded(child: Text("Update All")),
                            if (gotItems)
                              if (total != 0)
                                Text("($toUpdate/$total)")
                              else
                                const Text("No updates")
                          ],
                        ),
                        value: ifUpdateAll,
                        onChanged: gotItems && (total != 0)
                            ? (x) {
                                //TODO: implement prerelease
                                _setUpdateToAll(x);
                              }
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          //! Status message
          ValueListenableBuilder<String?>(
            valueListenable: _workStatusMessage!,
            builder: (context, statusMessage, _) {
              return AnimatedShowHide(
                isShown: statusMessage != null,
                showCurve: Curves.easeIn,
                hideCurve: Curves.easeOut,
                child: Text(
                  statusMessage ?? '',
                  textScaleFactor: 0.8,
                ),
                transitionBuilder: (context, animation, child) =>
                    FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    axisAlignment: -1,
                    sizeFactor: animation,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            child,
                          ],
                        ),
                        IconButton(
                          tooltip: "Stop",
                          onPressed: () {
                            operationContinue = false;
                            hideStatusMessage(_workStatusMessage);
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          //! Show unmatched only
          /*Obx(
            () {
              final bool notEligible =
                  _dependencies.data == null || _dependencies.isLoading;
              return ValueListenableBuilder<bool>(
                valueListenable: _showDifferencesOnly!,
                builder: (context, value, _) {
                  return SwitchListTile(
                    dense: true,
                    title: const Text("Show unmatched dependencies only"),
                    value: value,
                    onChanged: notEligible
                        ? null
                        : (x) {
                            _showDifferencesOnly!.value = x;
                          },
                  );
                },
              );
            },
          ),*/

          //! Update all
          /*Obx(
            () {
              final bool gotItems = !_dependencies.hasNoData;
              /*logExceptRelease(
                "Building update all, gotItems: $gotItems, unmatched: ${_countsCache.unmatched} ===============================================================",
              );*/
              final int total = _countsCache.unmatched;

              final int toUpdate = _countsCache.toUpdate;

              final bool ifUpdateAll = (total != 0) && (total == toUpdate);

              return SwitchListTile(
                dense: true,
                title: Row(
                  children: [
                    const Expanded(child: Text("Update All")),
                    if (gotItems)
                      if (total != 0)
                        Text("($toUpdate/$total)")
                      else
                        const Text("No updates")
                  ],
                ),
                value: ifUpdateAll,
                onChanged: gotItems && (total != 0)
                    ? (x) {
                        //TODO: implement prerelease
                        _setUpdateToAll(x);
                      }
                    : null,
              );
            },
          ),*/

          //! Search field
          /*SearchField(
            controller: _textEditingController!,
          ),

          //! How many results are showing
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Obx(() {
                if (_dependencies.data == null) {
                  return empty;
                }
                final int total = _countsCache.total;
                return ValueListenableBuilder<int?>(
                  valueListenable: _shownItems!,
                  builder: (context, shownItems, _) {
                    return Text(
                      "Total: $total, Showing: $shownItems",
                      textScaleFactor: 0.8,
                    );
                  },
                );
              }),
            ),
          ),*/

          //! Content
          ValueListenableBuilder<bool>(
            valueListenable: _showDifferencesOnly!,
            builder: (context, showDifferencesOnly, _) {
              return ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textEditingController!,
                builder: (context, textEditingValue, _) {
                  return DataGenerateObserver<
                      SingleGenerateObservable<RxList<UpdateInformation>>>(
                    observable: _dependencies,
                    builder: (dependenciesController) {
                      late final List<UpdateInformation> allItems;
                      {
                        Iterable<UpdateInformation> items =
                            dependenciesController.data!.toList();

                        if (showDifferencesOnly) {
                          items = items.where(
                            (element) => element.updateAvailableForAnyChannel,
                          );
                        }

                        final String filter =
                            textEditingValue.text.trim().toLowerCase();

                        if (filter.isNotEmpty) {
                          items = items.where(
                            (element) =>
                                element.name.toLowerCase().contains(filter),
                          );
                        }
                        allItems = items.toList();
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _shownItems!.value = allItems.length;
                      });

                      return Card(
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        child:
                            GroupedListView<UpdateInformation, DependencyType>(
                          sort: false,
                          useStickyGroupSeparators: true,
                          floatingHeader: true,
                          elements: allItems,
                          groupBy: (x) {
                            return x.dependencyType;
                          },
                          groupSeparatorBuilder: (dependencyType) => ColoredBox(
                            child: Obx(
                              () {
                                //logExceptRelease("Building separator");
                                // These are for subtitle elements
                                final _IndividualCountCache counts =
                                    _countsCache
                                            .individualCounts[dependencyType] ??
                                        _IndividualCountCache.zero();
                                final int stableUpdates = counts.updates;
                                final int majorStableUpdates =
                                    counts.majorUpdates;
                                final int higherStable = counts.higher;
                                final int unknownStable = counts.unknown;

                                final List<String> subtitleElements = [
                                  if (stableUpdates > 0)
                                    "Updates: $stableUpdates",
                                  if (majorStableUpdates > 0)
                                    "Major Updates: $majorStableUpdates",
                                  if (higherStable > 0) "Higher: $higherStable",
                                  if (unknownStable > 0)
                                    "Unknown: $unknownStable",
                                ];

                                // Title elements
                                final int toUpdate = counts.toUpdate;
                                final int unmatched = counts.unmatched;
                                final int total = counts.total;

                                final bool shouldShowCountElements =
                                    _dependencies.data != null;

                                final List<String> titleCountElements = [
                                  "Selected: $toUpdate",
                                  "Unmatches: $unmatched",
                                  "Total: $total",
                                ];

                                final List<String> titleElements = [
                                  dependencyType.prettyName,
                                  if (shouldShowCountElements)
                                    "(${titleCountElements.join(" / ")})",
                                ];

                                //logExceptRelease("Separator build complete");

                                return ListTile(
                                  title: Text(
                                    titleElements.join(" "),
                                    style: TextStyle(color: headerTextColor),
                                  ),
                                  subtitle: subtitleElements.isEmpty
                                      ? null
                                      : Text(
                                          subtitleElements.join(", "),
                                          style: TextStyle(
                                            color: headerTextColor,
                                          ),
                                          textScaleFactor: 0.8,
                                        ),
                                );
                              },
                            ),
                            color: primaryColor,
                          ),
                          indexedItemBuilder:
                              (context, updateInformation, index) {
                            return ItemView(
                              updateInformation: updateInformation,
                              onUpdateChannelChange: (channel) {
                                _setUpdateTo(
                                  index,
                                  channel,
                                );
                              },
                            );
                            // ignore: avoid_dynamic_calls
                            /*return Obx(
                              () {
                                //logExceptRelease("Building item: $index");
                                _dependencies.data; // Very important task
                                return Tooltip(
                                  waitDuration: const Duration(seconds: 1),
                                  message: updateInformation
                                          .updateTypeOfCurrentChannel
                                          ?.description ??
                                      "",
                                  child: SwitchListTile(
                                    key: ValueKey<UpdateInformation>(
                                      updateInformation,
                                    ),
                                    dense: true,
                                    //title: Text(updateInformation.toString()),
                                    title: Text(
                                      updateInformation.current.toString(),
                                    ),
                                    subtitle: Text(
                                      updateInformation.updateDetails,
                                      style: _getTextStyle(
                                        updateInformation.stableUpdateType,
                                      ),
                                      textScaleFactor: 0.9,
                                    ),
                                    value: updateInformation.setToUpdate,
                                    onChanged: (updateInformation
                                            .updateAvailableForAnyChannel)
                                        ? (shouldUpdate) {
                                            _setUpdateTo(
                                              index,
                                              shouldUpdate
                                                  ? ReleaseChannel.stable
                                                  : ReleaseChannel.none,
                                            );
                                          }
                                        : null,
                                  ),
                                );
                              },
                            );*/
                          },
                        ),
                      );
                    },
                    dataIsEmpty: (x) => x.data?.isEmpty ?? true,
                  );
                },
              );
            },
          ),

          //! Update button
          Obx(
            () {
              _dependencies.data;
              final FeedbackCallback? onPressed =
                  (_countsCache.toUpdate) <= 0 ? null : _update;
              return Padding(
                padding: const EdgeInsets.all(10),
                child: LoadingElevatedButton(
                  onPressed: onPressed,
                  child: const Text("Update"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CountsCache {
  int _total;
  int _unmatched;
  int _toUpdate;
  final Map<DependencyType, _IndividualCountCache> individualCounts = {};

  int get total => _total;
  int get unmatched => _unmatched;
  int get toUpdate => _toUpdate;

  _CountsCache.zero({
    // ignore: unused_element
    int total = 0,
    // ignore: unused_element
    int unmatched = 0,
    // ignore: unused_element
    int toUpdate = 0,
  })  : _total = total,
        _unmatched = unmatched,
        _toUpdate = toUpdate;

  void clear() {
    logExceptRelease("Clearing counts cache");
    _unmatched = 0;
    _total = 0;
    _toUpdate = 0;
    individualCounts.clear();
  }

  @override
  String toString() =>
      'CountsCache(\n\ttotal: $_total,\n\tunmatched: $_unmatched,\n\ttoUpdate: $_toUpdate\n\tindividualCounts: ${printMap(individualCounts)}\n)';

  void print() {
    logExceptRelease(toString());
  }

  // Generates Fresh Count Cache
  void setCountsCache({required List<UpdateInformation>? dependencies}) {
    //dependencies ??= _updates.data?.toList();

    clear();

    logExceptRelease("Generating counts cache...");

    if (dependencies == null || dependencies.isEmpty) {
      logExceptRelease(
        "Cannot generate counts cache, no dependencies found. Exiting.",
      );
      return;
    }

    final bool updateDoesNotExist = dependencies.first.stableUpdate == null;

    logExceptRelease("Updates present: ${!updateDoesNotExist}.");

    _total = dependencies.length;

    logExceptRelease("Total dependencies: $_total.");

    logExceptRelease("Iterating through dependencies...");

    for (final UpdateInformation element in dependencies) {
      // if individualCounts of current dependency type is null, initialize it with zeros
      if (individualCounts[element.dependencyType] == null) {
        individualCounts[element.dependencyType] = _IndividualCountCache.zero();
      }

      logExceptRelease("Current element: $element");

      ++individualCounts[element.dependencyType]!._total;
      logExceptRelease(
        "Incrementing individual counts for dependencyType: ${element.dependencyType.name}",
      );

      if (element.setToUpdate) {
        logExceptRelease("Incrementing toUpdate.");
        ++_toUpdate;
        ++individualCounts[element.dependencyType]!._toUpdate;
      }

      if (updateDoesNotExist) {
        logExceptRelease("Update data does not exist. Exiting...");
        continue;
      }

      final UpdateType updateType = element.updateTypeOfCurrentChannel!;

      // if an unmatch found, increasethe count
      if (element.updateAvailableForCurrentChannel) {
        logExceptRelease(
          "Incrementing unmatched, as update is available for current channel.",
        );
        // increase total unmatched
        ++_unmatched;

        // increase unmatched for the
        ++individualCounts[element.dependencyType]!._unmatched;
      }

      if (element.currentChannel == ReleaseChannel.prerelease) {
        ++individualCounts[element.dependencyType]!._prerelease;
      }

      logExceptRelease("Incrementing updateType count.");

      // Depending of the update type, increase corresponding counts
      switch (updateType) {
        case UpdateType.noUpdate:
          break;
        case UpdateType.update:
          ++individualCounts[element.dependencyType]!._updates;
          break;
        case UpdateType.majorUpdate:
          ++individualCounts[element.dependencyType]!._majorUpdates;
          break;
        case UpdateType.unknown:
          ++individualCounts[element.dependencyType]!._unknown;
          break;
        case UpdateType.higher:
          ++individualCounts[element.dependencyType]!._higher;
          break;
      }

      logExceptRelease(" ");
    }

    logExceptRelease("Counts cache set!");

    print();
  }

  // Modifies
  void modifyCountCacheForSingleChannelChange({
    required UpdateInformation oldDependency,
    required UpdateInformation newDependency,
  }) {
    final UpdateType? oldChannel = oldDependency.updateTypeOfCurrentChannel;
    final UpdateType? newChannel = newDependency.updateTypeOfCurrentChannel;
    final dependencyType = oldDependency.dependencyType;

    if (oldChannel == null || newChannel == null) {
      return;
    }

    if (newDependency.updateTo == ReleaseChannel.none) {
      // new dependency is just a false to update, decrease by 1
      _modifyChannelCountOfType(
        updateType: oldChannel,
        dependencyType: dependencyType,
        by: -1,
      );
    } else {
      // new dependency is true to update
      if (oldDependency.updateTo == ReleaseChannel.none) {
        // if old dependency WAS a false to update, increase by 1
        _modifyChannelCountOfType(
          updateType: newChannel,
          dependencyType: dependencyType,
          by: 1,
        );
      } else {
        // if old dependency was true to update, decrease the old by 1
        _modifyChannelCountOfType(
          updateType: oldChannel,
          dependencyType: dependencyType,
          by: -1,
        );
      }
    }
  }

  void _modifyChannelCountOfType({
    required UpdateType updateType,
    required DependencyType dependencyType,
    required int by,
  }) {
    _toUpdate += by;
    if (individualCounts[dependencyType] == null) {
      individualCounts[dependencyType] = _IndividualCountCache.zero();
    }
    ++individualCounts[dependencyType]!._toUpdate;
    logExceptRelease("CountsCache Modified by $by");
    print();
  }
}

String printMap(Map map) {
  return "\n\t{\n${map.entries.map<String>((e) => "${e.key} : ${e.value}").join(",\n")}\n\t}";
  /*return '''
{
  ${map.entries.map<String>(
            (e) =>
  '''
    ${e.key} : ${e.value}
  ''',
          ).join(",\n")}
}
''';*/
}

class _IndividualCountCache {
  int _updates;
  int _majorUpdates;
  int _higher;
  int _unknown;
  int _prerelease;
  int _toUpdate;
  int _total;
  int _unmatched;

  int get updates => _updates;
  int get majorUpdates => _majorUpdates;
  int get higher => _higher;
  int get unknown => _unknown;
  int get prerelease => _prerelease;
  int get toUpdate => _toUpdate;
  int get total => _total;
  int get unmatched => _unmatched;

  _IndividualCountCache.zero({
    // ignore: unused_element
    int updates = 0,
    // ignore: unused_element
    int majorUpdates = 0,
    // ignore: unused_element
    int higher = 0,
    // ignore: unused_element
    int unknown = 0,
    // ignore: unused_element
    int prerelease = 0,
    // ignore: unused_element
    int toUpdate = 0,
    // ignore: unused_element
    int total = 0,
    // ignore: unused_element
    int unmatched = 0,
  })  : _updates = updates,
        _majorUpdates = majorUpdates,
        _higher = higher,
        _unknown = unknown,
        _prerelease = prerelease,
        _toUpdate = toUpdate,
        _total = total,
        _unmatched = unmatched;

  @override
  String toString() {
    return 'IndividualCountCache(\n\tupdates: $_updates,\n\tmajorUpdates: $_majorUpdates,\n\thigher: $_higher,\n\tunknown: $_unknown,\n\tprerelease: $_prerelease,\n\ttoUpdate: $_toUpdate,\n\ttotal: $_total,\n\tunmatched: $_unmatched\n)';
  }
}
