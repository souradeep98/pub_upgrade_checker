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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
  final List<File> x = await pickFiles(
    allowMultiple: false,
    allowedExtensions: ["yaml"],
  );
  if (x.isEmpty) {
    return;
  }
  onPick(x.first);
}

class PickFile extends StatelessWidget {
  final void Function(File) onPick;

  const PickFile({
    Key? key,
    required this.onPick,
  }) : super(key: key);

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
    Key? key,
    required this.file,
    required this.onCloseFile,
    required this.onPickAnotherFile,
  }) : super(key: key);

  @override
  State<DependencyReviewer> createState() => _DependencyReviewerState();
}

class _DependencyReviewerState extends State<DependencyReviewer> {
  static const String _dependenciesTag = "dependencies";
  static const String _updatesTag = "updates";

  late SingleGenerateObservable<RxMap<DependencyType, RxList<Dependency>>>
      _dependencies;
  late SingleGenerateObservable<RxMap<Dependency, UpdateInformation>> _updates;
  //late ValueNotifier<Map<String, bool>> _updateList;
  ValueNotifier<String?>? _workStatusMessage;
  ValueNotifier<bool>? _showDifferencesOnly;
  //late ValueNotifier<bool> _updateMajorUpdates;
  TextEditingController? _textEditingController;
  Map<Dependency, DependencyType>? _dependencyToTypeMap;
  ValueNotifier<int?>? _shownItems;

  final List<Timer> _pendingOperations = [];

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
    _workStatusMessage = ValueNotifier<String?>(null);
    _shownItems = ValueNotifier<int?>(null);
    _dependencies = Get.put<
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
    );

    _updates =
        Get.put<SingleGenerateObservable<RxMap<Dependency, UpdateInformation>>>(
      SingleGenerateObservable<RxMap<Dependency, UpdateInformation>>(
        dataGenerator: (data) async {
          final Map<Dependency, UpdateInformation> result = {};
          final int totalCount = _dependencies.data?.values
                  .reduce(
                    (value, element) =>
                        RxList(value.toList() + element.toList()),
                  )
                  .length ??
              0;

          final Map<Dependency, Dependency> dependencyUpdates =
              await getUpdates(
            (_dependencies.data?[DependencyType.dependency]) ?? [],
            workStatusMessage: _workStatusMessage,
            wsmDepth: WSMDepth.medium,
            totalCount: totalCount,
          );

          final Map<Dependency, Dependency> devDependencyUpdates =
              await getUpdates(
            (_dependencies.data?[DependencyType.devDependency]) ?? [],
            workStatusMessage: _workStatusMessage,
            wsmDepth: WSMDepth.medium,
            initialCount:
                _dependencies.data?[DependencyType.dependency]?.length ?? 0,
            totalCount: totalCount,
          );

          result.addAll(
            dependencyUpdates.map<Dependency, UpdateInformation>(
              (key, value) {
                final UpdateType updateType =
                    UpdateType.getUpdateType(key, value);

                return MapEntry<Dependency, UpdateInformation>(
                  key,
                  UpdateInformation(
                    update: value,
                    updateType: updateType,
                    dependencyType: DependencyType.dependency,
                    shouldUpdate: updateType.shouldUpdate,
                  ),
                );
              },
            ),
          );

          result.addAll(
            devDependencyUpdates.map<Dependency, UpdateInformation>(
              (key, value) {
                final UpdateType updateType =
                    UpdateType.getUpdateType(key, value);
                return MapEntry<Dependency, UpdateInformation>(
                  key,
                  UpdateInformation(
                    update: value,
                    updateType: updateType,
                    dependencyType: DependencyType.devDependency,
                    shouldUpdate: updateType.shouldUpdate,
                  ),
                );
              },
            ),
          );
          return RxMap(result);
        },
        generateOnInit: false,
      ),
      tag: _updatesTag,
    );
    _generate();
  }

  void _disposeControllers({bool initiate = false}) {
    for (final Timer operationTimer in _pendingOperations) {
      log("Cancelling operation, pending operations: ${_pendingOperations.length}");
      operationTimer.cancel();
    }
    operationContinue = false;
    log("Pending Operations cancelled");
    _shownItems?.dispose();
    _shownItems = null;
    _textEditingController?.dispose();
    _textEditingController = null;
    _workStatusMessage?.dispose();
    _workStatusMessage = null;
    _showDifferencesOnly?.dispose();
    _showDifferencesOnly = null;
    _dependencyToTypeMap = null;
    log("Controllers Disposed");
    Future.wait([
      Get.delete<
          SingleGenerateObservable<RxMap<DependencyType, RxList<Dependency>>>>(
        tag: _dependenciesTag,
      ),
      Get.delete<
          SingleGenerateObservable<RxMap<Dependency, UpdateInformation>>>(
        tag: _updatesTag,
      ),
    ]).then((value) {
      log("GetX controllers Disposed");
      if (initiate) {
        _initiate();
      }
    });
  }

  void _generate() {
    _addToPendingOperations(() async {
      operationContinue = true;
      await _dependencies.generate();
      await _updates.generate();
      operationContinue = false;
    });
  }

  void _setShouldUpdate(Dependency dependency, bool shouldUpdate) {
    final Map<Dependency, UpdateInformation>? updatesSnapshot = _updates.data;
    if (updatesSnapshot == null) {
      return;
    }

    final UpdateInformation? updateInformation = updatesSnapshot[dependency];

    if (updateInformation == null) {
      return;
    }

    final UpdateInformation newUpdateInformation =
        updateInformation.setShouldUpdate(shouldUpdate);

    _updates.data![dependency] = newUpdateInformation;
  }

  void _setShouldUpdateAll(bool shouldUpdate) {
    if ((_dependencies.data == null) || (_updates.data == null)) {
      return;
    }

    for (final List<Dependency> dependencies in _dependencies.data!.values) {
      for (final Dependency dependency in dependencies) {
        final UpdateInformation? updateInformation = _updates.data![dependency];
        if (updateInformation != null && updateInformation.isUpgradable) {
          final UpdateInformation newUpdateInformation =
              updateInformation.setShouldUpdate(shouldUpdate);
          _updates.data![dependency] = newUpdateInformation;
        }
      }
    }
  }

  TextStyle? _getTextStyle(UpdateType? updateType) {
    if (updateType == null) {
      return null;
    }
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

  Timer _addToPendingOperations(Future<dynamic> Function() operation) {
    final Timer _timer = Timer(Duration.zero, () async {
      await operation();
    });
    _pendingOperations.add(_timer);
    return _timer;
  }

  Future<bool> _update() async {
    if (_updates.data == null) {
      return false;
    }
    operationContinue = true;
    await updateDependencies(
      file: widget.file,
      updateInformations: _updates.data!.values.toList(),
      workStatusMessage: _workStatusMessage,
      wsmDepth: WSMDepth.medium,
    );
    operationContinue = false;
    await _replaceCurrentDependenciesWithLatest();
    return true;
  }

  Future<void> _replaceCurrentDependenciesWithLatest() async {
    if ((_updates.data == null) || (_dependencies.data == null)) {
      return;
    }

    for (final DependencyType dependencyType in _dependencies.data!.keys) {
      final int lengthOfDependenciesOfCurrentType =
          _dependencies.data![dependencyType]!.length;
      for (int i = 0; i < lengthOfDependenciesOfCurrentType; ++i) {
        final Dependency oldDependency =
            _dependencies.data![dependencyType]![i];

        final UpdateInformation? updateInformation =
            _updates.data![oldDependency];

        if (updateInformation == null) {
          continue;
        }

        final Dependency update = updateInformation.update;

        _dependencies.data![dependencyType]![i] = update;
        _dependencyToTypeMap!.remove(oldDependency);
        _dependencyToTypeMap![update] = updateInformation.dependencyType;
      }
    }

    final List<Dependency> oldDependencies = _updates.data!.keys.toList();

    for (final Dependency oldDependency in oldDependencies) {
      final UpdateInformation updateInformation =
          _updates.data![oldDependency]!;
      _updates.data!.remove(oldDependency);
      _updates.data![updateInformation.update] = updateInformation;
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
            trailing: IconButton(
              tooltip: "Close File",
              onPressed: widget.onCloseFile,
              icon: const Icon(Icons.close),
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
            return AnimatedSwitcher(
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: statusMessage != null ? Text(statusMessage) : empty,
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    child,
                  ],
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
            final List<Dependency>? allDependencies = _dependencies.data?.values
                .reduce(
                  (value, element) => RxList(value.toList() + element.toList()),
                )
                .where(
                  (element) => _updates.data?[element]?.isUpgradable ?? false,
                )
                .toList();
            final int total = allDependencies?.length ?? 0;

            final int toUpdate = allDependencies
                    ?.where(
                      (element) =>
                          _updates.data?[element]?.shouldUpdate ?? false,
                    )
                    .length ??
                0;

            final bool updateAll = (total != 0) && (total == toUpdate);

            return SwitchListTile(
              dense: true,
              title: Row(
                children: [
                  const Expanded(child: Text("Update All")),
                  if ((_dependencies.data != null) && (_updates.data != null))
                    if (total != 0)
                      Text("($toUpdate/$total)")
                    else
                      const Text("No updates")
                ],
              ),
              value: updateAll,
              onChanged: ((_dependencies.data != null) &&
                      (_updates.data != null) &&
                      (total != 0))
                  ? _setShouldUpdateAll
                  : null,
            );
          },
        ),

        SearchField(
          controller: _textEditingController!,
        ),

        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Row(
              children: [
                Obx(
                  () {
                    final int total = _dependencies.data?.values
                            .reduce(
                              (value, element) =>
                                  RxList(value.toList() + element.toList()),
                            )
                            .length ??
                        0;

                    if (_dependencies.data == null) {
                      return empty;
                    }

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
                      SingleGenerateObservable<
                          RxMap<DependencyType, RxList<Dependency>>>>(
                    observable: _dependencies,
                    builder: (dependenciesC) {
                      _dependencyToTypeMap ??=
                          Map<Dependency, DependencyType>.fromEntries(
                        _dependencies.data!.entries
                            .map<
                                Iterable<MapEntry<Dependency, DependencyType>>>(
                              (outerEntry) => outerEntry.value
                                  .map<MapEntry<Dependency, DependencyType>>(
                                (e) => MapEntry<Dependency, DependencyType>(
                                  e,
                                  outerEntry.key,
                                ),
                              ),
                            )
                            .reduce(
                              (value, element) =>
                                  value.toList() + element.toList(),
                            ),
                      );

                      late final List<Dependency> allItems;

                      {
                        Iterable<Dependency> items = _dependencies.data!.values
                            .reduce(
                              (value, element) =>
                                  RxList(value.toList() + element.toList()),
                            )
                            .map<Dependency>((element) => element);

                        if (showDifferencesOnly) {
                          items = items.where(
                            (element) =>
                                _updates.data![element]?.isUpgradable ?? false,
                          );
                        }
                        final String filter =
                            textEditingValue.text.trim().toLowerCase();
                        if (filter.isNotEmpty) {
                          if (_updates.data == null) {
                            items = items.where(
                              (element) =>
                                  element.name.toLowerCase().contains(filter),
                            );
                          } else {
                            items = items.where(
                              (element) =>
                                  element.name.toLowerCase().contains(filter) ||
                                  (_updates.data![element]?.updateDetails
                                          .toLowerCase()
                                          .contains(filter) ??
                                      false),
                            );
                          }
                        }
                        allItems = items.toList();
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _shownItems!.value = allItems.length;
                      });

                      return Card(
                        child: GroupedListView<Dependency, DependencyType>(
                          sort: false,
                          useStickyGroupSeparators: true,
                          floatingHeader: true,
                          elements: allItems,
                          groupBy: (x) {
                            return _dependencyToTypeMap![x]!;
                          },
                          groupSeparatorBuilder: (x) => ColoredBox(
                            child: Obx(
                              () {
                                _updates.data;
                                final int updates = _dependencies.data?[x]
                                        ?.where(
                                          (element) =>
                                              _updates
                                                  .data?[element]?.updateType ==
                                              UpdateType.update,
                                        )
                                        .length ??
                                    0;
                                final int majorUpdates = _dependencies.data?[x]
                                        ?.where(
                                          (element) =>
                                              _updates
                                                  .data?[element]?.updateType ==
                                              UpdateType.majorUpdate,
                                        )
                                        .length ??
                                    0;
                                final int higher = _dependencies.data?[x]
                                        ?.where(
                                          (element) =>
                                              _updates
                                                  .data?[element]?.updateType ==
                                              UpdateType.higher,
                                        )
                                        .length ??
                                    0;
                                final int unknown = _dependencies.data?[x]
                                        ?.where(
                                          (element) =>
                                              _updates
                                                  .data?[element]?.updateType ==
                                              UpdateType.unknown,
                                        )
                                        .length ??
                                    0;
                                final List<String> subtitleElements = [
                                  if (updates > 0) "Updates: $updates",
                                  if (majorUpdates > 0)
                                    "Major Updates: $majorUpdates",
                                  if (higher > 0) "Higher: $higher",
                                  if (unknown > 0) "Unknown: $unknown",
                                ];

                                return ListTile(
                                  title: Obx(
                                    () {
                                      final int toUpdate =
                                          _dependencies.data?[x]
                                                  ?.where(
                                                    (element) =>
                                                        _updates.data?[element]
                                                            ?.shouldUpdate ??
                                                        false,
                                                  )
                                                  .length ??
                                              0;

                                      final int updates = _dependencies.data?[x]
                                              ?.where(
                                                (element) =>
                                                    _updates.data?[element]
                                                        ?.isUpgradable ??
                                                    false,
                                              )
                                              .length ??
                                          0;

                                      final List<String> counts = [
                                        if (_dependencies.data != null &&
                                            _updates.data != null)
                                          "Selected: $toUpdate",
                                        if (_dependencies.data != null &&
                                            _updates.data != null)
                                          "Updates: $updates",
                                        if (_dependencies.data != null)
                                          "Total: ${_dependencies.data![x]?.length}",
                                      ];

                                      final List<String> elements = [
                                        x.prettyName,
                                        if (counts.isNotEmpty)
                                          "(${counts.join(" / ")})",
                                      ];

                                      return Text(
                                        elements.join(" "),
                                        style:
                                            TextStyle(color: headerTextColor),
                                      );
                                    },
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
                          indexedItemBuilder: (context, item, index) {
                            return Obx(
                              () {
                                final UpdateInformation? updateInformation =
                                    _updates.data?[item];
                                return Tooltip(
                                  waitDuration: const Duration(seconds: 1),
                                  message: updateInformation
                                          ?.updateType.description ??
                                      "",
                                  child: SwitchListTile(
                                    key: ValueKey<Dependency>(item),
                                    dense: true,
                                    title: Text(item.toString()),
                                    subtitle: Text(
                                      updateInformation?.updateDetails ?? "",
                                      style: _getTextStyle(
                                        updateInformation?.updateType,
                                      ),
                                      textScaleFactor: 0.9,
                                    ),
                                    value: updateInformation?.shouldUpdate ??
                                        false,
                                    onChanged:
                                        (updateInformation?.isUpgradable ??
                                                false)
                                            ? (shouldUpdate) {
                                                _setShouldUpdate(
                                                  item,
                                                  shouldUpdate,
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
                    dataIsEmpty: (x) =>
                        x.data?.values.every((element) => element.isEmpty) ??
                        true,
                  );
                },
              );
            },
          ),
        ),

        //! Update button
        Obx(
          () {
            final FeedbackCallback? onPressed = _updates.data == null ||
                    (!_updates.data!.entries
                        .any((element) => element.value.shouldUpdate))
                ? null
                : _update;
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
