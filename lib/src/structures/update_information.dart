part of structures;

enum ReleaseChannel {
  stable,
  prerelease,
  none;

  Dependency _getUpdatedVersion(UpdateInformation updateInformation) {
    switch (updateInformation.updateTo) {
      case none:
        return updateInformation.current;
      case stable:
        return updateInformation.stableUpdate!;
      case prerelease:
        return updateInformation.prereleaseUpdate!;
    }
  }
}

class UpdateInformation extends Equatable {
  final Dependency current;
  final Dependency? stableUpdate;
  final Dependency? prereleaseUpdate;
  final DependencyType dependencyType;
  final ReleaseChannel updateTo;

  UpdateType get stableUpdateType =>
      UpdateType.getUpdateType(current, stableUpdate);
  UpdateType get prereleaseUpdateType =>
      UpdateType.getUpdateType(current, prereleaseUpdate);

  //UpdateTo? get updateTo => _updateTo;
  ReleaseChannel get currentChannel {
    if (stableUpdate == null) {
      throw "Unable to detect current channel! Update data is empty!";
    }
    if ((prereleaseUpdate != null) && (current > stableUpdate!)) {
      return ReleaseChannel.prerelease;
    } else {
      return ReleaseChannel.stable;
    }
  }

  UpdateType? get updateType {
    if (stableUpdate == null) {
      return null;
    }
    switch (currentChannel) {
      case ReleaseChannel.stable:
        return stableUpdateType;
      case ReleaseChannel.prerelease:
        return prereleaseUpdateType;
      case ReleaseChannel.none:
        return UpdateType.noUpdate;
    }
  }

  bool get isStableUpgradable => stableUpdateType != UpdateType.noUpdate;
  bool get isPrereleaseUpgradable =>
      prereleaseUpdateType != UpdateType.noUpdate;

  bool get updateAvailable => isStableUpgradable || isPrereleaseUpgradable;

  bool get updateAvailableForCurrentChannel {
    switch (currentChannel) {
      case ReleaseChannel.stable:
        return isStableUpgradable;
      case ReleaseChannel.prerelease:
        return isPrereleaseUpgradable;
      case ReleaseChannel.none:
        return false;
    }
  }

  String get updateDetails {
    if (stableUpdate == null) {
      return "";
    }
    return prereleaseUpdate != null
        ? "${stableUpdateType.displayName}: ${stableUpdate!.versionConstraint}, prerelease: ${prereleaseUpdate!.versionConstraint}"
        : "${stableUpdateType.displayName}: ${stableUpdate!.versionConstraint}";
  }

  String get name => current.name;

  bool get isUpdating => updateTo != ReleaseChannel.none;

  const UpdateInformation({
    required this.current,
    this.stableUpdate,
    this.prereleaseUpdate,
    required this.dependencyType,
    this.updateTo = ReleaseChannel.none,
  });

  bool isSame(Object other) =>
      ((other is Dependency) && (other.name == current.name)) ||
      ((other is UpdateInformation) && isSame(other.current));

  @override
  List<Object?> get props =>
      [stableUpdate, prereleaseUpdate, dependencyType, updateTo];

  UpdateInformation copyWith({
    Dependency? current,
    Dependency? stableUpdate,
    Dependency? prereleaseUpdate,
    DependencyType? dependencyType,
    ReleaseChannel? updateTo,
  }) {
    return UpdateInformation(
      current: current ?? this.current,
      stableUpdate: stableUpdate ?? this.stableUpdate,
      prereleaseUpdate: prereleaseUpdate ?? this.prereleaseUpdate,
      dependencyType: dependencyType ?? this.dependencyType,
      updateTo: updateTo ?? this.updateTo,
    );
  }

  UpdateInformation updatedVersion() => copyWith(
        current: updateTo._getUpdatedVersion(this),
        updateTo: ReleaseChannel.none,
      );

  @override
  String toString() {
    return 'UpdateInformation(\n\tcurrent: $current,\n\tstableUpdate: $stableUpdate,\n\tprereleaseUpdate: $prereleaseUpdate,\n\tdependencyType: $dependencyType,\n\tupdateTo: $updateTo,\n)';
  }
}
