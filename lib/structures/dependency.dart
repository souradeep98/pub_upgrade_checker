part of structures;

class Dependency extends Equatable {
  final String name;
  final VersionConstraint versionConstraint;

  const Dependency({
    required this.name,
    required this.versionConstraint,
  });

  static List<Dependency> listFromMap(Map map) => map
      .cast<String, String>()
      .entries
      .map(
        (e) => Dependency(
          name: e.key,
          versionConstraint: VersionConstraint.parse(e.value),
        ),
      )
      .toList();

  factory Dependency.fromString(String string) {
    final List<String> parts =
        string.split(":").map<String>((e) => e.trim()).toList();
    return Dependency(
      name: parts[0],
      versionConstraint: VersionConstraint.parse(parts[1]),
    );
  }

  @override
  List<Object?> get props => [name, versionConstraint];

  @override
  bool get stringify => false;

  @override
  String toString() {
    return "$name: $versionConstraint";
  }

  bool isSame(Object other) =>
      ((other is Dependency) && (other.name == name)) ||
      ((other is UpdateInformation) && isSame(other.update));

  /*bool operator >(Object other) {
    if (other is Dependency) {
      return other.versionConstraint.version > versionConstraint.version;
    }

    if (other is Version) {
      return other > versionConstraint.version;
    }

    if (other is VersionConstraint) {
      return other.version > versionConstraint.version;
    }

    return false;
    /*return ((other is Dependency) &&
            (other.versionConstraint.version > versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (other.version > versionConstraint.version)) ||
        ((other is Version) && other > versionConstraint.version);*/
  }*/

  bool operator >(Object other) {
    assert(isSame(other));
    return ((other is UpdateInformation) && this > other.update) ||
        ((other is Dependency) &&
            (versionConstraint.version > other.versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (versionConstraint.version > other.version)) ||
        ((other is Version) && versionConstraint.version > other);
  }

  bool operator <(Object other) {
    assert(isSame(other));
    return ((other is UpdateInformation) && this < other.update) ||
        ((other is Dependency) &&
            (versionConstraint.version < other.versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (versionConstraint.version < other.version)) ||
        ((other is Version) && versionConstraint.version < other);
  }

  bool operator >=(Object other) {
    assert(isSame(other));
    return ((other is UpdateInformation) && this >= other.update) ||
        ((other is Dependency) &&
            (versionConstraint.version >= other.versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (versionConstraint.version >= other.version)) ||
        ((other is Version) && versionConstraint.version >= other);
  }

  bool operator <=(Object other) {
    assert(isSame(other));
    return ((other is UpdateInformation) && this <= other.update) ||
        ((other is Dependency) &&
            (versionConstraint.version <= other.versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (versionConstraint.version <= other.version)) ||
        ((other is Version) && versionConstraint.version <= other);
  }

  bool allows(Object other) =>
      ((other is UpdateInformation) && isSame(other) && allows(other.update)) ||
      ((other is Dependency) &&
          isSame(other) &&
          versionConstraint.allowsAny(other.versionConstraint)) ||
      ((other is VersionConstraint) && versionConstraint.allowsAny(other)) ||
      ((other is Version) && versionConstraint.allows(other));
}
