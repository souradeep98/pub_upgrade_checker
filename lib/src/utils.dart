library utils;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_essentials/flutter_essentials.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pub_upgrade_checker/src/globals.dart';
import 'package:pub_upgrade_checker/src/structures.dart';
import 'package:yaml/yaml.dart' as yaml;
import 'package:html/dom.dart' as html;
import 'package:http/http.dart' as http;
import 'package:yaml_edit/yaml_edit.dart';

extension VersionConstraintExtension on VersionConstraint {
  Version get version {
    final String versionString = toString().replaceFirst("^", "").trim();
    //logExceptRelease("Converting to version: $versionString");
    return Version.parse(versionString);
  }
}

Future<Map<DependencyType, List<Dependency>>> getDependencies(
  File file, {
  ValueNotifier<String?>? workStatusMessage,
  WSMDepth wsmDepth = WSMDepth.light,
}) async {
  void setStatus(StatusMessage message) {
    if (workStatusMessage == null) {
      return;
    }
    setStatusMessage(
      message: message,
      yourDepth: wsmDepth,
      workStatusMesageNotifier: workStatusMessage,
    );
  }

  checkOperation();

  setStatus(
    const StatusMessage(
      message: "Loading dependencies...",
      depth: WSMDepth.light,
    ),
  );

  setStatus(
    const StatusMessage(
      message: "Reading file...",
      depth: WSMDepth.deep,
    ),
  );

  final String yamlContent = await file.readAsString();

  checkOperation();

  setStatus(
    const StatusMessage(
      message: "Loading yaml content...",
      depth: WSMDepth.deep,
    ),
  );

  final yaml.YamlDocument document = yaml.loadYamlDocument(yamlContent);

  checkOperation();

  setStatus(
    const StatusMessage(
      message: "Reading dependencies...",
      depth: WSMDepth.deep,
    ),
  );

  final Map contentAsJson = jsonDecode(jsonEncode(document.contents)) as Map;

  checkOperation();

  final Map dependenciesMap =
      (contentAsJson[DependencyType.dependency.pubspecName] as Map)
          .cast<String, dynamic>()
          .filterOutWhere((key, value) {
    final bool exclude = (key == "flutter") || (value is! String);
    if (!exclude) {
      setStatus(
        StatusMessage(
          message: "Loading dependency: $key",
          depth: WSMDepth.deep,
        ),
      );
    }
    return exclude;
  });

  checkOperation();

  final Map devDependenciesMap =
      (contentAsJson[DependencyType.devDependency.pubspecName] as Map)
          .cast<String, dynamic>()
          .filterOutWhere(
    (key, value) {
      final bool exclude = (key == "flutter_test") || (value is! String);
      if (!exclude) {
        setStatus(
          StatusMessage(
            message: "Loading dev dependency: $key",
            depth: WSMDepth.deep,
          ),
        );
      }
      return exclude;
    },
  );

  checkOperation();

  final List<Dependency> dependencies = Dependency.listFromMap(dependenciesMap);

  final List<Dependency> devDependencies =
      Dependency.listFromMap(devDependenciesMap);

  checkOperation();

  setStatus(
    const StatusMessage(
      message: "Dependencies loaded!",
      depth: WSMDepth.light,
    ),
  );

  //emptyStatusMessage(workStatusMessage);

  return {
    DependencyType.dependency: dependencies,
    DependencyType.devDependency: devDependencies,
  };
}

Future<Map<Dependency, Dependency>> getUpdates(
  List<Dependency> dependencies, {
  ValueNotifier<String?>? workStatusMessage,
  WSMDepth wsmDepth = WSMDepth.light,
  int? initialCount,
  int? totalCount,
}) async {
  void setStatus(StatusMessage message) {
    if (workStatusMessage == null) {
      return;
    }
    setStatusMessage(
      message: message,
      yourDepth: wsmDepth,
      workStatusMesageNotifier: workStatusMessage,
    );
  }

  const String pubBaseUrl = "https://pub.dev/packages/";
  const String selector =
      "body > main > div.detail-wrapper.-active.-has-info-box > div.detail-header.-is-loose > div > div > div > h1 > span > div > span";

  final Map<Dependency, Dependency> results = {};

  setStatus(
    const StatusMessage(
      message: "Checking for updates...",
      depth: WSMDepth.light,
    ),
  );

  checkOperation();

  final length = dependencies.length;
  for (int i = 0; i < length; ++i) {
    checkOperation();
    final Dependency x = dependencies[i];
    final int currentCount =
        (initialCount != null) ? (initialCount + i + 1) : (i + 1);
    setStatus(
      StatusMessage(
        message:
            "Checking update for: ${x.name} ($currentCount/${totalCount ?? length})",
        depth: WSMDepth.medium,
      ),
    );
    logExceptRelease("");
    logExceptRelease("Local: ${x.name}: ${x.versionConstraint}");
    final Uri uri = Uri.parse(pubBaseUrl + x.name);
    final http.Response response = await http.get(uri);

    final html.Document htmlDoc = html.Document.html(response.body);

    final html.Element? element = htmlDoc.querySelector(selector);

    if (element == null) {
      logExceptRelease(
        "Could Not Find Element in html for $x",
        error: "Could Not Find Element in html",
      );
      continue;
    }

    logExceptRelease("HTML element: ${element.innerHtml}");

    final Dependency update = Dependency.fromString(element.innerHtml);

    logExceptRelease("Pub: $update");

    results.addAll({
      x: update,
    });

    final bool updateFound = update > x;

    logExceptRelease(updateFound ? "Update available!" : "Latest!");

    if (updateFound) {
      setStatus(
        StatusMessage(
          message: "Update found for ${x.name}",
          depth: WSMDepth.deep,
        ),
      );
    }
  }

  //! Calls APIs for every dependency together
  /*Future<void> _checker(Dependency x) async {
    _setStatusMessage(
      StatusMessage(
        message: "Checking update for ${x.name}",
        depth: WSMDepth.deep,
      ),
    );

    //logExceptRelease("\nLocal: ${x.name}: ${x.versionConstraint}");
    final Uri uri = Uri.parse(pubBaseUrl + x.name);
    final Response response = await HTTP.get(uri);

    final html.Document htmlDoc = html.Document.html(response.body);

    final html.Element? element = htmlDoc.querySelector(selector);

    if (element == null) {
      logExceptRelease(
        "Could Not Find Element in html for $x",
        error: "Could Not Find Element in html",
      );
      return;
    }

    //logExceptRelease("HTML element: ${element.innerHtml}");

    final Dependency update = Dependency.fromString(element.innerHtml);

    //logExceptRelease("Pub: $update");

    results.addAll({
      x: update,
    });

    //logExceptRelease(update > x ? "Update available!" : "Latest!");
  }
  dependencies.forEach(_checker);*/

  setStatus(
    const StatusMessage(
      message: "Finished Checking for Updates!",
      depth: WSMDepth.deep,
    ),
  );

  hideStatusMessage(workStatusMessage);

  return results;
}

Future<void> updateDependencies({
  required File file,
  required List<UpdateInformation> updateInformations,
  ValueNotifier<String?>? workStatusMessage,
  WSMDepth wsmDepth = WSMDepth.light,
}) async {
  void setStatus(StatusMessage message) {
    if (workStatusMessage == null) {
      return;
    }
    setStatusMessage(
      message: message,
      yourDepth: wsmDepth,
      workStatusMesageNotifier: workStatusMessage,
    );
  }

  setStatus(
    const StatusMessage(
      message: "Loading dependencies...",
      depth: WSMDepth.light,
    ),
  );

  setStatus(
    const StatusMessage(
      message: "Reading file...",
      depth: WSMDepth.deep,
    ),
  );

  checkOperation();

  final String yamlContent = await file.readAsString();

  checkOperation();

  setStatus(
    const StatusMessage(
      message: "Loading yaml content...",
      depth: WSMDepth.deep,
    ),
  );

  final YamlEditor yamlEditor = YamlEditor(yamlContent);

  checkOperation();

  setStatus(
    const StatusMessage(
      message: "Filtering dependencies...",
      depth: WSMDepth.deep,
    ),
  );

  final List<UpdateInformation> filteredUpdateInformations =
      updateInformations.where((element) => element.shouldUpdate).toList();

  checkOperation();

  setStatus(
    const StatusMessage(
      message: "Updating dependencies...",
      depth: WSMDepth.deep,
    ),
  );

  final int updateInformationLength = filteredUpdateInformations.length;

  logExceptRelease("Before update: $yamlEditor");

  for (int i = 0; i < updateInformationLength; ++i) {
    checkOperation();
    final UpdateInformation updateInformation = filteredUpdateInformations[i];
    final String updateVersion =
        updateInformation.update.versionConstraint.toString();
    final String rootNode = updateInformation.dependencyType.pubspecName;
    final String dependencyName = updateInformation.update.name;
    final String dependencyTypeName = updateInformation.dependencyType.typeName;
    setStatus(
      StatusMessage(
        message:
            "Updating $dependencyTypeName: $dependencyName (${i + 1}/$updateInformationLength)",
        depth: WSMDepth.deep,
      ),
    );
    yamlEditor.update(
      [rootNode, dependencyName],
      updateVersion,
    );
  }

  logExceptRelease("After update: $yamlEditor");

  checkOperation();

  setStatus(
    const StatusMessage(
      message: "Dependencies updated!",
      depth: WSMDepth.deep,
    ),
  );

  setStatus(
    const StatusMessage(
      message: "Writing to file...",
      depth: WSMDepth.light,
    ),
  );

  await file.writeAsString(yamlEditor.toString());

  setStatus(
    const StatusMessage(
      message: "Writing to file complete!",
      depth: WSMDepth.medium,
    ),
  );

  hideStatusMessage(workStatusMessage);
}
