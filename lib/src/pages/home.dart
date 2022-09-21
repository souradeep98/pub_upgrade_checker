part of pages;

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

  /*
  Future<void> _test() async {
    final File file = File("D:\\tests\\pubspec1.yaml");

    final String yamlContent = await file.readAsString();

    //final yaml.YamlDocument document = yaml.loadYamlDocument(yamlContent);

    final YamlEditor yamlEditor = YamlEditor(yamlContent);

    /*final Map contentAsJson = jsonDecode(jsonEncode(document.contents)) as Map;

    final Map dependenciesMap = (contentAsJson["dependencies"] as Map)
        .cast<String, dynamic>()
        .filterOutWhere((key, value) => key == "flutter" || value is! String);
    final Map devDependenciesMap = (contentAsJson["dev_dependencies"] as Map)
        .cast<String, dynamic>()
        .filterOutWhere(
          (key, value) => key == "flutter_test" || value is! String,
        );

    const String pubBaseUrl = "https://pub.dev/packages/";

    final List<Dependency> dependencies =
        Dependency.listFromMap(dependenciesMap);

    final List<Dependency> devDependencies =
        Dependency.listFromMap(devDependenciesMap);

    final List<Dependency> allDependencies = dependencies + devDependencies;

    for (final Dependency x in allDependencies) {
      logExceptRelease("\nDependency: ${x.name}: ${x.versionConstraint}");
      final Uri uri = Uri.parse(pubBaseUrl + x.name);
      final Response response = await HTTP.get(uri);

      final html.Document htmlDoc = html.Document.html(response.body);

      final html.Element? element = htmlDoc.querySelector(
        "body > main > div.detail-wrapper.-active.-has-info-box > div.detail-header.-is-loose > div > div > div > h1 > span > div > span",
      );

      if (element == null) {
        logExceptRelease("Could Not Find Element in html");
        continue;
      }

      logExceptRelease("HTML element: ${element.innerHtml}");

      final Dependency update = Dependency.fromString(element.innerHtml);

      logExceptRelease("Update: $update");

      logExceptRelease(update > x ? "Update available!" : "Latest!");
    }*/

    logExceptRelease("Before update: $yamlEditor");

    yamlEditor.update(
      [
        "dependencies",
        "cupertino_icons",
      ],
      null,
    );

    logExceptRelease("After update: $yamlEditor");

    //yamlEditor.toString();
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PUCAppBar(),
      body: SafeArea(
        child: ValueListenableBuilder<File?>(
          valueListenable: _selectedFile,
          builder: (context, file, pickFile) {
            if (file == null) {
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
            );
          },
          child: PickFile(
            onPick: (x) {
              _selectedFile.value = x;
            },
          ),
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

class PickFile extends StatelessWidget {
  final void Function(File) onPick;

  const PickFile({
    super.key,
    required this.onPick,
  });

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
            ElevatedButton(
              onPressed: () async {
                await _pickFile(onPick);
              },
              child: const Text("Pick"),
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
  //static const String _dependenciesTag = "dependencies";
  static const String _updatesTag = "updates";

  /*late SingleGenerateObservable<RxMap<DependencyType, RxList<Dependency>>>
      _dependencies;*/
  late SingleGenerateObservable<RxList<UpdateInformation>> _updates;
  ValueNotifier<String?>? _workStatusMessage;
  ValueNotifier<bool>? _showDifferencesOnly;
  TextEditingController? _textEditingController;
  //Map<Dependency, DependencyType>? _dependencyToTypeMap;
  ValueNotifier<int?>? _shownItems;
  final _CountsCache _countsCache = _CountsCache();

  final List<CancelableOperation<dynamic>> _pendingOperations = [];

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
    if (oldWidget.file != widget.file) {
      _disposeControllers(initiate: true);
    }
  }

  void _initiate() {
    _textEditingController = TextEditingController();
    _showDifferencesOnly = ValueNotifier<bool>(false);
    _workStatusMessage = ValueNotifier<String?>(null)
      ..addListener(() {
        logExceptRelease("Status Message: ${_workStatusMessage?.value}");
      });
    _shownItems = ValueNotifier<int?>(null);
    /*_dependencies = Get.put<
        SingleGenerateObservable<RxMap<DependencyType, RxList<Dependency>>>>(
      SingleGenerateObservable<RxMap<DependencyType, RxList<Dependency>>>(
        dataGenerator: (data) async {
          final Map<DependencyType, List<Dependency>> dependencies =
              await getDependencies(
            widget.file,
            workStatusMessage: _workStatusMessage,
          );

          return RxMap<DependencyType, RxList<Dependency>>(
            dependencies.map<DependencyType, RxList<Dependency>>(
              (key, value) => MapEntry<DependencyType, RxList<Dependency>>(
                key,
                RxList(value),
              ),
            ),
          );
        },
        generateOnInit: false,
      ),
      tag: _dependenciesTag,
    );*/

    _updates = Get.put<SingleGenerateObservable<RxList<UpdateInformation>>>(
      SingleGenerateObservable<RxList<UpdateInformation>>(
        dataGenerator: (data) async {
          final List<UpdateInformation> dependencies = await getDependencies(
            widget.file,
            workStatusMessage: _workStatusMessage,
          );

          return RxList<UpdateInformation>(dependencies);
        },
        generateOnInit: false,
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
    _addToPendingOperations(() async {
      operationContinue = true;
      //await _dependencies.generate();
      await _updates.generate();
      await _getUpdates();
      operationContinue = false;
    });
  }

  Future<bool> _getUpdates() async {
    final List<UpdateInformation>? dependencies = _updates.data;
    if (dependencies == null) {
      return false;
    }
    final List<UpdateInformation> result = await getUpdates(dependencies);
    _updates.data?.replaceRange(0, dependencies.length, result);

    // Generate counts cache
    logExceptRelease("Generating Counts Cache");
    _countsCache.total = result.length;
    _countsCache.toUpdate = 0;
    for (final UpdateInformation element in result) {
      if (_countsCache.individualCounts[element.dependencyType] == null) {
        _countsCache.individualCounts[element.dependencyType] =
            _IndividualCountCache.zero();
      }

      {
        final int currentCount =
            _countsCache.individualCounts[element.dependencyType]!.total!;
        _countsCache.individualCounts[element.dependencyType]!.total =
            currentCount + 1;
      }

      final UpdateType updateType = element.updateType!;

      if (updateType != UpdateType.noUpdate) {
        final int currentCount =
            _countsCache.individualCounts[element.dependencyType]!.unmatched!;
        _countsCache.individualCounts[element.dependencyType]!.unmatched =
            currentCount + 1;
      }

      switch (updateType) {
        case UpdateType.noUpdate:
          break;
        case UpdateType.update:
          final int currentCount =
              _countsCache.individualCounts[element.dependencyType]!.updates!;
          _countsCache.individualCounts[element.dependencyType]!.updates =
              currentCount + 1;
          _countsCache.toUpdate = _countsCache.toUpdate! + 1;
          break;
        case UpdateType.majorUpdate:
          final int currentCount = _countsCache
              .individualCounts[element.dependencyType]!.majorUpdates!;
          _countsCache.individualCounts[element.dependencyType]!.majorUpdates =
              currentCount + 1;
          break;
        case UpdateType.unknown:
          final int currentCount =
              _countsCache.individualCounts[element.dependencyType]!.unknown!;
          _countsCache.individualCounts[element.dependencyType]!.unknown =
              currentCount + 1;
          break;

        case UpdateType.higher:
          final int currentCount =
              _countsCache.individualCounts[element.dependencyType]!.higher!;
          _countsCache.individualCounts[element.dependencyType]!.higher =
              currentCount + 1;
          break;
      }
    }

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

    _updates.data!.replaceRange(0, 1, updatedDependencies);
    _countsCache.clear();
  }

  CancelableOperation<dynamic> _addToPendingOperations(
    Future Function() operation,
  ) {
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

  void _setUpdateTo(
    UpdateInformation updateInformation,
    ReleaseChannel updateTo,
  ) {
    if (_updates.data == null) {
      return;
    }

    final int index = _updates.data!.indexOf(updateInformation);

    if (index == -1) {
      logExceptRelease("Element not found!");
      return;
    }

    final UpdateInformation newUpdateInformation = updateInformation.copyWith(
      updateTo: updateTo,
    );

    _updates.data![index] = newUpdateInformation;
  }

  void _setUpdateToAll(ReleaseChannel updateTo) {
    if (_updates.data == null) {
      return;
    }

    final List<UpdateInformation> updatedList = _updates.data!
        .map<UpdateInformation>(
          (element) => element.copyWith(
            updateTo: updateTo,
          ),
        )
        .toList();

    _countsCache.toUpdate =
        updateTo == ReleaseChannel.none ? 0 : updatedList.length;

    _updates.data!.replaceRange(0, _updates.data!.length, updatedList);
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
              child: Text(statusMessage ?? ''),
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
            final List<UpdateInformation>? allDependencies =
                _updates.data?.toList();
            final int total = _countsCache.total ??
                (_countsCache.total = allDependencies?.length ?? 0);

            final int toUpdate = _countsCache.toUpdate ??
                (_countsCache.toUpdate = allDependencies
                        ?.where(
                          (element) => element.isUpdating,
                        )
                        .length ??
                    0);

            final bool ifUpdateAll = (total != 0) && (total == toUpdate);

            return SwitchListTile(
              dense: true,
              title: Row(
                children: [
                  const Expanded(child: Text("Update All")),
                  if (allDependencies != null)
                    if (total != 0)
                      Text("($toUpdate/$total)")
                    else
                      const Text("No updates")
                ],
              ),
              value: ifUpdateAll,
              onChanged: (allDependencies != null) && (total != 0)
                  ? (x) {
                      //TODO: implement prerelease
                      final ReleaseChannel updateTo =
                          x ? ReleaseChannel.stable : ReleaseChannel.none;
                      _setUpdateToAll(updateTo);
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
            child: Row(
              children: [
                Obx(
                  () {
                    if (_updates.data == null) {
                      return empty;
                    }

                    final int total = _countsCache.total ??
                        (_countsCache.total = _updates.data!.length);

                    return Text(
                      "Total: $total",
                      textScaleFactor: 0.9,
                    );
                  },
                ),
                ValueListenableBuilder<int?>(
                  valueListenable: _shownItems!,
                  builder: (context, shownItems, _) {
                    return Text(
                      ", Showing: $shownItems",
                      textScaleFactor: 0.9,
                    );
                  },
                ),
              ],
            ),
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
                            (element) => element.updateAvailable,
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

                                /*stableUpdates = _updates.data
                                        ?.where(
                                          (element) =>
                                              (element.stableUpdateType ==
                                                  UpdateType.update) &&
                                              (element.dependencyType ==
                                                  dependencyType),
                                        )
                                        .length ??
                                    0;

                                majorStableUpdates = _updates.data
                                        ?.where(
                                          (element) =>
                                              (element.stableUpdateType ==
                                                  UpdateType.majorUpdate) &&
                                              (element.dependencyType ==
                                                  dependencyType),
                                        )
                                        .length ??
                                    0;

                                higherStable = _updates.data
                                        ?.where(
                                          (element) =>
                                              element.stableUpdateType ==
                                              UpdateType.higher,
                                        )
                                        .length ??
                                    0;

                                unknownStable = _updates.data
                                        ?.where(
                                          (element) =>
                                              element.stableUpdateType ==
                                              UpdateType.higher,
                                        )
                                        .length ??
                                    0;*/

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
                                final int unmatches = counts.unmatched!;
                                final int total = counts.total!;

                                final bool shouldShowCountElements =
                                    _updates.data != null;

                                final List<String> titleCountElements = [
                                  "Selected: $toUpdate",
                                  "Updates: $unmatches",
                                  "Total: $total",
                                ];

                                final List<String> titleElements = [
                                  dependencyType.prettyName,
                                  if (shouldShowCountElements)
                                    "(${titleCountElements.join(" / ")})",
                                ];

                                return ListTile(
                                  title: Text(
                                    titleElements.join(" "),
                                    style: TextStyle(color: headerTextColor),
                                  ),
                                  subtitle: subtitleElements.isEmpty
                                      ? null
                                      : Text(
                                          subtitleElements.join(", "),
                                          style:
                                              TextStyle(color: headerTextColor),
                                          textScaleFactor: 0.8,
                                        ),
                                );
                              },
                            ),
                            color: primaryColor,
                          ),
                          indexedItemBuilder:
                              (context, updateInformation, index) {
                            return Obx(
                              () {
                                _updates.data; // Very important task
                                return Tooltip(
                                  waitDuration: const Duration(seconds: 1),
                                  message: updateInformation
                                          .updateType?.description ??
                                      "",
                                  child: SwitchListTile(
                                    key: ValueKey<UpdateInformation>(
                                      updateInformation,
                                    ),
                                    dense: true,
                                    title: Text(updateInformation.toString()),
                                    subtitle: Text(
                                      updateInformation.updateDetails,
                                      style: _getTextStyle(
                                        updateInformation.stableUpdateType,
                                      ),
                                      textScaleFactor: 0.9,
                                    ),
                                    value: updateInformation.isUpdating,
                                    onChanged:
                                        (updateInformation.updateAvailable)
                                            ? (shouldUpdate) {
                                                _setUpdateTo(
                                                  updateInformation,
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
            final FeedbackCallback? onPressed = ((_updates.data == null) ||
                    (!_updates.data!.any((element) {
                      //logExceptRelease("${element.value}");
                      return element.isUpdating;
                    })))
                ? null
                : _update;

            //logExceptRelease("Update onPressed: $onPressed");
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
  int? toUpdate;
  final Map<DependencyType, _IndividualCountCache> individualCounts = {};

  void clear() {
    total = null;
    toUpdate = null;
    individualCounts.clear();
  }
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
}
