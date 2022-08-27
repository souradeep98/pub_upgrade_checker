part of structures;

class UpdateInformation extends Equatable {
  final Dependency update;
  final UpdateType updateType;
  final DependencyType dependencyType;
  final bool shouldUpdate;
  final bool isUpgradable;
  final String updateDetails;

  UpdateInformation({
    required this.update,
    required this.updateType,
    required this.dependencyType,
    required this.shouldUpdate,
  }) : isUpgradable = updateType != UpdateType.noUpdate, updateDetails = "${updateType.displayName}: ${update.versionConstraint}";

  UpdateInformation setShouldUpdate(bool value) {
    return UpdateInformation(
      update: update,
      updateType: updateType,
      dependencyType: dependencyType,
      shouldUpdate: value,
    );
  }

  bool isSame(Object other) =>
      ((other is Dependency) && (other.name == update.name)) ||
      ((other is UpdateInformation) && isSame(other.update));

  bool operator >(Object other) {
    assert(isSame(other));
    return ((other is UpdateInformation) && update > other.update) ||
        ((other is Dependency) &&
            (update.versionConstraint.version >
                other.versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (update.versionConstraint.version > other.version)) ||
        ((other is Version) && update.versionConstraint.version > other);
  }

  bool operator <(Object other) {
    assert(isSame(other));
    return ((other is UpdateInformation) && update < other.update) ||
        ((other is Dependency) &&
            (update.versionConstraint.version <
                other.versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (update.versionConstraint.version < other.version)) ||
        ((other is Version) && update.versionConstraint.version < other);
  }

  bool operator >=(Object other) {
    assert(isSame(other));
    return ((other is UpdateInformation) && update >= other.update) ||
        ((other is Dependency) &&
            (update.versionConstraint.version >=
                other.versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (update.versionConstraint.version >= other.version)) ||
        ((other is Version) && update.versionConstraint.version >= other);
  }

  bool operator <=(Object other) {
    assert(isSame(other));
    return ((other is UpdateInformation) && update <= other.update) ||
        ((other is Dependency) &&
            (update.versionConstraint.version <=
                other.versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (update.versionConstraint.version <= other.version)) ||
        ((other is Version) && update.versionConstraint.version <= other);
  }

  bool allows(Object other) =>
      ((other is UpdateInformation) && isSame(other) && update.allows(other)) ||
      ((other is Dependency) &&
          update.isSame(other) &&
          update.versionConstraint.allowsAny(other.versionConstraint)) ||
      ((other is VersionConstraint) &&
          update.versionConstraint.allowsAny(other)) ||
      ((other is Version) && update.versionConstraint.allows(other));

  @override
  List<Object?> get props => [update, updateType, dependencyType, shouldUpdate];
}
