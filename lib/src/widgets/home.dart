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
                : DependencyReviewer(
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
        child: PickFile(
          onPick: (x) {
            _selectedFile.value = x;
          },
        ),
      ),
    );
  }
}

Future<void> _pickFile(void Function(File) onPick) async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ["yaml"],
  );
  /*final List<File> x = await pickFiles(
    allowMultiple: false,
    allowedExtensions: ["yaml"],
  );*/
  if (result == null) {
    return;
  }
  onPick(File(result.files.single.path!));
}

class PickFile extends StatefulWidget {
  final void Function(File) onPick;

  const PickFile({
    super.key,
    required this.onPick,
  });

  @override
  State<PickFile> createState() => _PickFileState();
}

class _PickFileState extends State<PickFile> {
  final GlobalKey<FavouredButtonState> _favouredButtonKey =
      GlobalKey<FavouredButtonState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Timer(timeStamp + DesktopFrame.initialAnimationDuration, () {
        _favouredButtonKey.currentState?.startBlinking();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
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
            ),
          ],
        ),
      ),
    );
  }
}

class DependencyReviewer extends StatefulWidget {
  final VoidCallback onCloseFile;
  final void Function(File) onPickAnotherFile;
  final File file;

  const DependencyReviewer({
    super.key,
    required this.file,
    required this.onCloseFile,
    required this.onPickAnotherFile,
  });

  @override
  State<DependencyReviewer> createState() => _DependencyReviewerState();
}

class _DependencyReviewerState extends State<DependencyReviewer> {
  static const String _updatesTag = "updates";

  late SingleGenerateObservable<RxList<UpdateInformation>> _updates;
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
  void didUpdateWidget(covariant DependencyReviewer oldWidget) {
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

    _updates = Get.put<SingleGenerateObservable<RxList<UpdateInformation>>>(
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
      tag: _updatesTag,
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
      /*Get.delete<
          SingleGenerateObservable<RxMap<DependencyType, RxList<Dependency>>>>(
        tag: _dependenciesTag,
      ),*/
      Get.delete<
          SingleGenerateObservable<RxMap<Dependency, UpdateInformation>>>(
        tag: _updatesTag,
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
      await _updates.generate();
      await _getUpdates();
      operationContinue = false;
    });
  }

  Future<bool> _getUpdates() async {
    logExceptRelease("Getting updates");
    final List<UpdateInformation>? dependencies = _updates.data;
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
    _updates.data = RxList<UpdateInformation>(result);
    hideStatusMessage(_workStatusMessage);
    return true;
  }

  Future<bool> _update() async {
    final List<UpdateInformation>? dependencies = _updates.data?.toList();
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
    final List<UpdateInformation>? dependencies = _updates.data?.toList();
    if (dependencies == null) {
      return;
    }

    final List<UpdateInformation> updatedDependencies =
        dependencies.map<UpdateInformation>((e) => e.updatedVersion()).toList();

    _countsCache.setCountsCache(
      //refresh: true,
      dependencies: updatedDependencies,
    );

    _updates.data = RxList<UpdateInformation>(updatedDependencies);
  }

  void _setUpdateTo(int index, ReleaseChannel updateTo) {
    if (_updates.data == null) {
      return;
    }

    final UpdateInformation updateInformation = _updates.data![index];

    final UpdateInformation newUpdateInformation = updateInformation.copyWith(
      updateTo: updateTo,
    );

    // count cache
    _countsCache.modifyCountCacheForSingleChannelChange(
      oldDependency: updateInformation,
      newDependency: newUpdateInformation,
    );

    _updates.data![index] = newUpdateInformation;
  }

  //! Update All
  void _setUpdateToAll(bool shouldUpdate) {
    if (_updates.data == null) {
      return;
    }

    final List<UpdateInformation> updatedList = _updates.data!
        .map<UpdateInformation>(
          (element) => element.shouldUpdate(shouldUpdate),
        )
        .toList();

    // counts cache
    _countsCache.setCountsCache(dependencies: updatedList);

    _updates.data = RxList<UpdateInformation>(updatedList);
  }

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
    logExceptRelease("_DependencyReviewerState Build is running");
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color headerTextColor =
        primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Column(
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
              transitionBuilder: (context, animation, child) => FadeTransition(
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
        Obx(
          () {
            final bool notEligible =
                _updates.data == null || _updates.isLoading;
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
        ),

        //! Update all
        Obx(
          () {
            final bool gotItems = !_updates.hasNoData;
            logExceptRelease(
              "Building update all, gotItems: $gotItems, unmatched: ${_countsCache.unmatched} ===============================================================",
            );
            final int total = _countsCache.unmatched ?? 0;

            final int toUpdate = _countsCache.toUpdate ?? 0;

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
        ),

        //! Search field
        SearchField(
          controller: _textEditingController!,
        ),

        //! How many results are showing
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Obx(() {
              if ((_updates.data == null) || (_countsCache.total == null)) {
                return empty;
              }
              final int total = _countsCache.total!;
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
        ),

        //! Content
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _showDifferencesOnly!,
            builder: (context, showDifferencesOnly, _) {
              return ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textEditingController!,
                builder: (context, textEditingValue, _) {
                  return DataGenerateObserver<
                      SingleGenerateObservable<RxList<UpdateInformation>>>(
                    observable: _updates,
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
                                final int stableUpdates = counts.updates!;
                                final int majorStableUpdates =
                                    counts.majorUpdates!;
                                final int higherStable = counts.higher!;
                                final int unknownStable = counts.unknown!;

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
                                final int toUpdate = counts.toUpdate!;
                                final int unmatched = counts.unmatched!;
                                final int total = counts.total!;

                                final bool shouldShowCountElements =
                                    _updates.data != null;

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
                            // ignore: avoid_dynamic_calls
                            return Obx(
                              () {
                                logExceptRelease("Building item: $index");
                                _updates.data; // Very important task
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
                            );
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
        ),

        //! Update button
        Obx(
          () {
            _updates.data;
            final FeedbackCallback? onPressed =
                (_countsCache.toUpdate ?? 0) <= 0 ? null : _update;

            logExceptRelease("Update onPressed: $onPressed");
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
    );
  }
}

class _CountsCache {
  int? total;
  int? unmatched;
  int? toUpdate;
  final Map<DependencyType, _IndividualCountCache> individualCounts = {};

  _CountsCache.zero({
    // ignore: unused_element
    this.total = 0,
    // ignore: unused_element
    this.unmatched = 0,
    // ignore: unused_element
    this.toUpdate = 0,
  });

  void clear() {
    unmatched = 0;
    total = 0;
    toUpdate = 0;
    individualCounts.clear();
  }

  @override
  String toString() =>
      'CountsCache(\n\ttotal: $total,\n\tunmatched: $unmatched,\n\ttoUpdate: $toUpdate\n\tindividualCounts: ${printMap(individualCounts)}\n)';

  void print() {
    logExceptRelease(toString());
  }

  // Generates Fresh Count Cache
  void setCountsCache({required List<UpdateInformation>? dependencies}) {
    logExceptRelease("Generating counts cache");
    //dependencies ??= _updates.data?.toList();

    clear();

    if (dependencies == null || dependencies.isEmpty) {
      logExceptRelease("Cannot generate counts cache, no dependencies found.");
      return;
    }

    final bool updateDoesNotExist = dependencies.first.stableUpdate == null;

    total = dependencies.length;

    for (final UpdateInformation element in dependencies) {
      // if individualCounts of current dependency type is null, initialize it with zeros
      if (individualCounts[element.dependencyType] == null) {
        individualCounts[element.dependencyType] = _IndividualCountCache.zero();
      }

      individualCounts[element.dependencyType]!.total =
          individualCounts[element.dependencyType]!.total! + 1;

      if (element.setToUpdate) {
        toUpdate = toUpdate! + 1;
        individualCounts[element.dependencyType]!.toUpdate =
            individualCounts[element.dependencyType]!.toUpdate! + 1;
      }

      if (updateDoesNotExist) {
        continue;
      }

      final UpdateType updateType = element.updateTypeOfCurrentChannel!;

      // if an unmatch found, increasethe count
      if (element.updateAvailableForCurrentChannel) {
        // increase total unmatched
        unmatched = unmatched! + 1;

        // increase unmatched for the
        individualCounts[element.dependencyType]!.unmatched =
            individualCounts[element.dependencyType]!.unmatched! + 1;
      }

      // Depending of the update type, increase corresponding counts
      switch (updateType) {
        case UpdateType.noUpdate:
          break;
        case UpdateType.update:
          individualCounts[element.dependencyType]!.updates =
              individualCounts[element.dependencyType]!.updates! + 1;
          break;
        case UpdateType.majorUpdate:
          individualCounts[element.dependencyType]!.majorUpdates =
              individualCounts[element.dependencyType]!.majorUpdates! + 1;
          break;
        case UpdateType.unknown:
          individualCounts[element.dependencyType]!.unknown =
              individualCounts[element.dependencyType]!.unknown! + 1;
          break;

        case UpdateType.higher:
          individualCounts[element.dependencyType]!.higher =
              individualCounts[element.dependencyType]!.higher! + 1;
          break;
      }
    }
    logExceptRelease("Counts cache set");
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
    toUpdate = toUpdate! + by;
    if (individualCounts[dependencyType] == null) {
      individualCounts[dependencyType] = _IndividualCountCache.zero();
    }
    individualCounts[dependencyType]!.toUpdate =
        individualCounts[dependencyType]!.toUpdate! + 1;
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
  int? updates;
  int? majorUpdates;
  int? higher;
  int? unknown;
  int? prerelease;
  int? toUpdate;
  int? total;
  int? unmatched;

  _IndividualCountCache.zero({
    // ignore: unused_element
    this.updates = 0,
    // ignore: unused_element
    this.majorUpdates = 0,
    // ignore: unused_element
    this.higher = 0,
    // ignore: unused_element
    this.unknown = 0,
    // ignore: unused_element
    this.prerelease = 0,
    // ignore: unused_element
    this.toUpdate = 0,
    // ignore: unused_element
    this.total = 0,
    // ignore: unused_element
    this.unmatched = 0,
  });

  @override
  String toString() {
    return 'IndividualCountCache(\n\tupdates: $updates,\n\tmajorUpdates: $majorUpdates,\n\thigher: $higher,\n\tunknown: $unknown,\n\tprerelease: $prerelease,\n\ttoUpdate: $toUpdate,\n\ttotal: $total,\n\tunmatched: $unmatched\n)';
  }
}
