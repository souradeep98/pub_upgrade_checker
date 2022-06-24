import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_utilities/flutter_utilities.dart';
import 'package:pub_upgrade_checker/dependency.dart';
import 'package:pub_upgrade_checker/status_message.dart';
import 'package:yaml/yaml.dart' as yaml;
import 'package:html/dom.dart' as html;

Future<Pair<List<Dependency>, List<Dependency>>> getDependencies(
  File file, {
  ValueNotifier<String?>? workStatusMessage,
  WSMDepth wsmDepth = WSMDepth.light,
}) async {
  void _setStatus(StatusMessage message) {
    if (workStatusMessage == null) {
      return;
    }
    setStatusMessage(
      message: message,
      yourDepth: wsmDepth,
      workStatusMesageNotifier: workStatusMessage,
    );
  }

  _setStatus(
    const StatusMessage(
      message: "Loading dependencies...",
      depth: WSMDepth.light,
    ),
  );

  _setStatus(
    const StatusMessage(
      message: "Reading file...",
      depth: WSMDepth.deep,
    ),
  );

  final String yamlContent = await file.readAsString();

  _setStatus(
    const StatusMessage(
      message: "Loading yaml content...",
      depth: WSMDepth.deep,
    ),
  );

  final yaml.YamlDocument document = yaml.loadYamlDocument(yamlContent);

  _setStatus(
    const StatusMessage(
      message: "Reading dependencies...",
      depth: WSMDepth.deep,
    ),
  );

  final Map contentAsJson = jsonDecode(jsonEncode(document.contents)) as Map;

  final Map dependenciesMap =
      (contentAsJson[DependencyType.dependency.pubspecName] as Map)
          .cast<String, dynamic>()
          .filterOutWhere((key, value) {
    final bool exclude = (key == "flutter") || (value is! String);
    if (!exclude) {
      _setStatus(
        StatusMessage(
          message: "Loading dependency: $key",
          depth: WSMDepth.deep,
        ),
      );
    }
    return exclude;
  });
  final Map devDependenciesMap =
      (contentAsJson[DependencyType.devDependency.pubspecName] as Map)
          .cast<String, dynamic>()
          .filterOutWhere(
    (key, value) {
      final bool exclude = (key == "flutter_test") || (value is! String);
      if (!exclude) {
        _setStatus(
          StatusMessage(
            message: "Loading dev dependency: $key",
            depth: WSMDepth.deep,
          ),
        );
      }
      return exclude;
    },
  );

  final List<Dependency> dependencies = Dependency.listFromMap(dependenciesMap);

  final List<Dependency> devDependencies =
      Dependency.listFromMap(devDependenciesMap);

  _setStatus(
    const StatusMessage(
      message: "Dependencies loaded!",
      depth: WSMDepth.light,
    ),
  );

  workStatusMessage?.value = "";

  return Pair<List<Dependency>, List<Dependency>>(
    dependencies,
    devDependencies,
  );
}

Future<Map<Dependency, Dependency>> getUpdates(
  List<Dependency> dependencies, {
  ValueNotifier<String?>? workStatusMessage,
  WSMDepth wsmDepth = WSMDepth.light,
}) async {
  void _setStatus(StatusMessage message) {
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

  _setStatus(
    const StatusMessage(
      message: "Checking for updates...",
      depth: WSMDepth.light,
    ),
  );

  //for (final Dependency x in dependencies) {
  final length = dependencies.length;
  for (int i = 0; i < length; ++i) {
    final Dependency x = dependencies[i];
    _setStatus(
      StatusMessage(
        message: "Checking update for: ${x.name} ($i/$length)",
        depth: WSMDepth.medium,
      ),
    );
    logExceptRelease("");
    logExceptRelease("Local: ${x.name}: ${x.versionConstraint}");
    final Uri uri = Uri.parse(pubBaseUrl + x.name);
    final Response response = await HTTP.get(uri);

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
      _setStatus(
        StatusMessage(
          message: "Update found for ${x.name}",
          depth: WSMDepth.deep,
        ),
      );
    }
  }

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

  _setStatus(
    const StatusMessage(
      message: "Finished Checking for Updates!",
      depth: WSMDepth.deep,
    ),
  );

  workStatusMessage?.value = "";

  return results;
}
