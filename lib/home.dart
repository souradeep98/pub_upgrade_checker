import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:grouped_list/grouped_list.dart';
import 'package:pub_upgrade_checker/dependency.dart';
import 'package:pub_upgrade_checker/helpers.dart';
import 'package:pub_upgrade_checker/status_message.dart';
import 'package:yaml/yaml.dart' as yaml;

import 'package:yaml_edit/yaml_edit.dart';

import 'package:flutter_utilities/flutter_utilities.dart';

//import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as html;

import 'package:sticky_headers/sticky_headers.dart';

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
  }

  @override
  void dispose() {
    _selectedFile.dispose();
    super.dispose();
  }

  /*Future<void> _test() async {
    if (_selectedFile.value == null) {
      return;
    }

    final File file = _selectedFile.value!;

    final String yamlContent = await file.readAsString();

    final yaml.YamlDocument document = yaml.loadYamlDocument(yamlContent);

    final YamlEditor yamlEditor = YamlEditor(yamlContent);

    final Map contentAsJson = jsonDecode(jsonEncode(document.contents)) as Map;

    final Map dependenciesMap = (contentAsJson["dependencies"] as Map)
        .cast<String, dynamic>()
        .filterOutWhere((key, value) => key == "flutter" || value is! String);
    final Map devDependenciesMap = (contentAsJson["dev_dependencies"] as Map)
        .cast<String, dynamic>()
        .filterOutWhere(
          (key, value) => key == "flutter_test" || value is! String,
        );

    const String pubBaseUrl = "https://pub.dev/packages/";

    /*final Map<String, String> allDependencies = {
      ...dependenciesMap
          .cast<String, dynamic>()
          .filterOutWhere((key, value) => key == "flutter" || value is! String),
      ...devDependenciesMap.cast<String, dynamic>().filterOutWhere(
          (key, value) => key == "flutter_test" || value is! String),
    };*/

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
    }

    logExceptRelease("Before update: $yamlEditor");

    yamlEditor.update(
      [
        "dependencies",
        "cupertino_icons",
      ],
      null,
    );

    logExceptRelease("After update: $yamlEditor");

    /*document.startImplicit;
    document.endImplicit;
    document.span;
    document.tagDirectives;
    document.versionDirective;
    document.contents;*/

    /*logExceptRelease(
      "StartImplicit: ${document.startImplicit}\nEndImplicit: ${document.endImplicit}\nSpan: ${document.span}\nTagDirectives: ${document.tagDirectives}\nVersionDirective: ${document.versionDirective}\nContents: ${jsonEncode(document.contents)}",
    );*/
  }*/

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

  late SingleGenerateObservable<Pair<List<Dependency>, List<Dependency>>>
      _dependencies;
  late SingleGenerateObservable<
      Map<Dependency, Pair<Dependency, DependencyType>>> _updates;
  late ValueNotifier<Map<String, bool>> _updateList;
  late ValueNotifier<String?> _workStatusMessage;
  late ValueNotifier<bool> _showDifferencesOnly;
  late ValueNotifier<bool> _updateMajorUpdates;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _initiate();
    _generate();
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
      _disposeControllers();
      _initiate();
      _generate();
    }
  }

  void _initiate() {
    _textEditingController = TextEditingController();
    _updateMajorUpdates = ValueNotifier<bool>(false);
    _showDifferencesOnly = ValueNotifier<bool>(false);
    _updateList = ValueNotifier<Map<String, bool>>({});
    _workStatusMessage = ValueNotifier<String?>(null);
    _dependencies = Get.put<
        SingleGenerateObservable<Pair<List<Dependency>, List<Dependency>>>>(
      SingleGenerateObservable<Pair<List<Dependency>, List<Dependency>>>(
        dataGenerator: (data) => getDependencies(
          widget.file,
          workStatusMessage: _workStatusMessage,
        ),
        generateOnInit: false,
      ),
      tag: _dependenciesTag,
    );
    _updates = Get.put<
        SingleGenerateObservable<
            Map<Dependency, Pair<Dependency, DependencyType>>>>(
      SingleGenerateObservable<
          Map<Dependency, Pair<Dependency, DependencyType>>>(
        dataGenerator: (data) async {
          final Map<Dependency, Pair<Dependency, DependencyType>> result = {};
          final Map<Dependency, Dependency> dependencyUpdates =
              await getUpdates(
            (_dependencies.data?.a) ?? [],
            workStatusMessage: _workStatusMessage,
            wsmDepth: WSMDepth.medium,
          );
          final Map<Dependency, Dependency> devDependencyUpdates =
              await getUpdates(
            (_dependencies.data?.b) ?? [],
            workStatusMessage: _workStatusMessage,
            wsmDepth: WSMDepth.medium,
          );
          result.addAll(
            dependencyUpdates.map<Dependency, Pair<Dependency, DependencyType>>(
              (key, value) =>
                  MapEntry<Dependency, Pair<Dependency, DependencyType>>(
                key,
                Pair<Dependency, DependencyType>(
                  value,
                  DependencyType.dependency,
                ),
              ),
            ),
          );
          result.addAll(
            devDependencyUpdates
                .map<Dependency, Pair<Dependency, DependencyType>>(
              (key, value) =>
                  MapEntry<Dependency, Pair<Dependency, DependencyType>>(
                key,
                Pair<Dependency, DependencyType>(
                  value,
                  DependencyType.devDependency,
                ),
              ),
            ),
          );
          return result;
        },
        generateOnInit: false,
      ),
      tag: _updatesTag,
    );
  }

  void _disposeControllers() {
    _textEditingController.dispose();
    _updateList.dispose();
    _workStatusMessage.dispose();
    _updateMajorUpdates.dispose();
    _showDifferencesOnly.dispose();
    Get.delete<
        SingleGenerateObservable<Pair<List<Dependency>, List<Dependency>>>>(
      tag: _dependenciesTag,
    );
    Get.delete<SingleGenerateObservable<Map<Dependency, Dependency>>>(
      tag: _updatesTag,
    );
  }

  Future<void> _generate() async {
    await _dependencies.generate();
    await _updates.generate();
    _processUpdateList();
    _workStatusMessage.value = null;
  }

  void _processUpdateList() {
    _workStatusMessage.value = "Processing update list...";
    if (_updates.data == null) {
      logExceptRelease(
        "Could not process update list as updates are empty.",
        error: "Could not process update list as updates are empty.",
      );
      return;
    }
    _updateList.value = Map<String, bool>.fromEntries(
      _updates.data
              ?.filterOutWhere((key, value) => key == value.a)
              .values
              .map<MapEntry<String, bool>>(
                (e) => MapEntry<String, bool>(
                  e.a.name,
                  true,
                ),
              ) ??
          [],
    );
    _workStatusMessage.value = "";
    logExceptRelease("Updated list: ${jsonEncode(_updateList.value)}");
  }

  void _setShouldUpdate(Dependency dependency, bool shouldUpdate) {
    final Map<String, bool> snapshot = Map<String, bool>.from(_updateList.value)
      ..[dependency.name] = shouldUpdate;
    _updateList.value = snapshot;
  }

  void _setShouldUpdateAll(bool shouldUpdate) {
    _updateList.value = _updateList.value.keys.presenceMap<bool>(
      defaultValue: shouldUpdate,
      presenceValue: false,
      elements: [],
    );
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
          valueListenable: _workStatusMessage,
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
              valueListenable: _showDifferencesOnly,
              builder: (context, value, _) {
                return SwitchListTile(
                  dense: true,
                  title: const Text("Show unmatched dependencies only"),
                  value: value,
                  onChanged: notEligible
                      ? null
                      : (x) {
                          _showDifferencesOnly.value = x;
                        },
                );
              },
            );
          },
        ),

        //! Update all
        ValueListenableBuilder<Map<String, bool>>(
          valueListenable: _updateList,
          builder: (context, updateList, child) {
            /*final bool value = updateList.values.every(
              (element) => element,
            );*/
            final int total = updateList.length;

            final int toUpdate = updateList.values
                .where(
                  (element) => element,
                )
                .length;
            final bool updateAll = total == toUpdate;

            return SwitchListTile(
              dense: true,
              title: Row(
                children: [
                  Expanded(child: child!),
                  Text("($toUpdate/$total)"),
                ],
              ),
              value: updateAll,
              onChanged: (shouldUpdate) {
                _setShouldUpdateAll(shouldUpdate);
              },
            );
          },
          child: const Text("Update All"),
        ),

        SearchField(
          controller: _textEditingController,
        ),

        //! Content
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _showDifferencesOnly,
            builder: (context, showDifferencesOnly, _) {
              return DataGenerateObserver<
                  SingleGenerateObservable<
                      Pair<List<Dependency>, List<Dependency>>>>(
                observable: _dependencies,
                builder: (dependenciesC) {
                  final List<Dependency> dependencies =
                      (showDifferencesOnly && _updates.data != null)
                          ? ((dependenciesC.data?.a ?? [])
                              .where(
                                (element) =>
                                    _updates.data![element]!.a != element,
                              )
                              .toList())
                          : (dependenciesC.data?.a ?? []);

                  final List<Dependency> devDependencies =
                      (showDifferencesOnly && _updates.data != null)
                          ? ((dependenciesC.data?.b ?? [])
                              .where(
                                (element) =>
                                    _updates.data![element]!.a != element,
                              )
                              .toList())
                          : (dependenciesC.data?.b ?? []);

                  final List<Dependency> allItems = [
                    ...dependencies,
                    ...devDependencies,
                  ];

                  /*final List<List<Dependency>> combined = [
                    if (dependencies.isNotEmpty) dependencies,
                    if (devDependencies.isNotEmpty) devDependencies,
                  ];

                  final List<DependencyType> presentDependencyTypes = [
                    if (dependencies.isNotEmpty) DependencyType.dependency,
                    if (devDependencies.isNotEmpty)
                      DependencyType.devDependency,
                  ];*/

                  final Map<Dependency, DependencyType> dependeencytoType = {
                    ...Map<Dependency, DependencyType>.fromEntries(
                      dependencies.map<MapEntry<Dependency, DependencyType>>(
                        (e) => MapEntry<Dependency, DependencyType>(
                          e,
                          DependencyType.dependency,
                        ),
                      ),
                    ),
                    ...Map<Dependency, DependencyType>.fromEntries(
                      devDependencies.map<MapEntry<Dependency, DependencyType>>(
                        (e) => MapEntry<Dependency, DependencyType>(
                          e,
                          DependencyType.devDependency,
                        ),
                      ),
                    ),
                  };

                  return Card(
                    child: GroupedListView<Dependency, DependencyType>(
                      sort: false,
                      useStickyGroupSeparators: true,
                      floatingHeader: true,
                      elements: allItems,
                      groupBy: (x) {
                        return dependeencytoType[x]!;
                      },
                      groupSeparatorBuilder: (x) => Container(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              Obx(
                                () {
                                  if (_updates.data == null) {
                                    return Text(
                                      x.prettyName,
                                      style: TextStyle(color: headerTextColor),
                                    );
                                  }
                                  return Text(
                                    "${x.prettyName} (${_updates.data!.filterWhere(
                                          (key, value) => value.b == x,
                                        ).length})",
                                    style: TextStyle(color: headerTextColor),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        color: primaryColor,
                      ),
                      indexedItemBuilder: (context, item, index) {
                        return ValueListenableBuilder<Map<String, bool>>(
                          key: ValueKey<Dependency>(item),
                          valueListenable: _updateList,
                          builder: (context, updateList, updateInfo) {
                            return SwitchListTile(
                              key: ValueKey<Dependency>(item),
                              dense: true,
                              title: Text(item.toString()),
                              subtitle: updateInfo,
                              value: updateList[item.name] ?? false,
                              onChanged: updateList.containsKey(item.name)
                                  ? (shouldUpdate) {
                                      _setShouldUpdate(
                                        item,
                                        shouldUpdate,
                                      );
                                    }
                                  : null,
                            );
                          },
                          child: Obx(
                            () {
                              if (_updates.data == null ||
                                  !_updates.data!.containsKey(item)) {
                                return empty;
                              }
                              final Dependency update = _updates.data![item]!.a;
                              if (update == item) {
                                return Text(
                                  "Latest: ${item.versionConstraint}",
                                );
                              }
                              if (update > item) {
                                if (update.allows(item)) {
                                  return Text(
                                    "UPDATE: ${update.versionConstraint.toString()}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                }
                                return Text(
                                  "MAJOR UPDATE: ${update.versionConstraint.toString()}",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              }
                              if (update < item) {
                                return Text(
                                  "Higher: ${update.versionConstraint.toString()}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              }
                              return Text(
                                "Unmatched: ${update.versionConstraint.toString()}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );

                  /*return Card(
                    child: ListView.builder(
                      itemBuilder: (context, outerIndex) => StickyHeader(
                        key: ValueKey<String>(
                          presentDependencyTypes[outerIndex].prettyName,
                        ),
                        header: Container(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                Obx(
                                  () {
                                    if (_updates.data == null) {
                                      return Text(
                                        presentDependencyTypes[outerIndex]
                                            .prettyName,
                                        style:
                                            TextStyle(color: headerTextColor),
                                      );
                                    }
                                    return Text(
                                      "${presentDependencyTypes[outerIndex].prettyName} (${_updates.data!.filterWhere(
                                            (key, value) =>
                                                value.b ==
                                                presentDependencyTypes[
                                                    outerIndex],
                                          ).length})",
                                      style: TextStyle(color: headerTextColor),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          color: primaryColor,
                        ),
                        content: ListView.builder(
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final Dependency item = combined[outerIndex][index];
                            return ValueListenableBuilder<Map<String, bool>>(
                              key: ValueKey<Dependency>(item),
                              valueListenable: _updateList,
                              builder: (context, updateList, updateInfo) {
                                return SwitchListTile(
                                  key: ValueKey<Dependency>(item),
                                  dense: true,
                                  title: Text(item.toString()),
                                  subtitle: updateInfo,
                                  value: updateList[item.name] ?? false,
                                  onChanged: updateList.containsKey(item.name)
                                      ? (shouldUpdate) {
                                          _setShouldUpdate(
                                            item,
                                            shouldUpdate,
                                          );
                                        }
                                      : null,
                                );
                              },
                              child: Obx(
                                () {
                                  if (_updates.data == null ||
                                      !_updates.data!.containsKey(item)) {
                                    return empty;
                                  }
                                  final Dependency update =
                                      _updates.data![item]!.a;
                                  if (update == item) {
                                    return Text(
                                      "Latest: ${item.versionConstraint}",
                                    );
                                  }
                                  if (update > item) {
                                    if (update.allows(item)) {
                                      return Text(
                                        "UPDATE: ${update.versionConstraint.toString()}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      );
                                    }
                                    return Text(
                                      "MAJOR UPDATE: ${update.versionConstraint.toString()}",
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    );
                                  }
                                  if (update < item) {
                                    return Text(
                                      "Higher: ${update.versionConstraint.toString()}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    );
                                  }
                                  return Text(
                                    "Unmatched: ${update.versionConstraint.toString()}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          itemCount: combined[outerIndex].length,
                        ),
                      ),
                      itemCount: combined.length,
                    ),
                  );*/
                },
                dataIsEmpty: (x) =>
                    (x.data?.a.isEmpty ?? true) && (x.data?.b.isEmpty ?? true),
              );
            },
          ),
        ),

        //! Update button
        ValueListenableBuilder<Map<String, bool>>(
          valueListenable: _updateList,
          builder: (context, updateList, _) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed:
                    updateList.values.any((element) => element) ? () {} : null,
                child: const Text("Update"),
              ),
            );
          },
        ),
      ],
    );
  }
}
