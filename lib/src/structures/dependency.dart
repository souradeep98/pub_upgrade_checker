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

  /// Example: google_fonts: ^3.0.1
  factory Dependency.fromConstraintString(String string) {
    final List<String> parts =
        string.split(":").map<String>((e) => e.trim()).toList();
    return Dependency(
      name: parts[0],
      versionConstraint: VersionConstraint.parse(parts[1]),
    );
  }

  /// Example:
  factory Dependency.fromString(String string) {
    final List<String> parts =
        string.split(":").map<String>((e) => e.trim()).toList();
    return Dependency(
      name: parts[0],
      versionConstraint: VersionConstraint.parse(parts[1]),
    );
  }

  static Dependency? maybeFromMetaDataHTMLElement(html.Element? element) {
    if (element == null) {
      return null;
    }
    //logExceptRelease("Metadata element: ${element.innerHtml}");
    final int prereleaseIndex = element.innerHtml.indexOf("Prerelease:");
    if (prereleaseIndex == -1) {
      return null;
    }
    final String prereleaseSubstring =
        element.innerHtml.substring(prereleaseIndex);

    //logExceptRelease(prereleaseSubstring);

    final int prereleaseRefStartIndex = prereleaseSubstring.indexOf('"');
    final int prereleaseRefEndIndex = prereleaseSubstring.indexOf(
      '"',
      prereleaseRefStartIndex + 1,
    );

    final String prereleaseRefSubstring = prereleaseSubstring.substring(
      prereleaseRefStartIndex + 1,
      prereleaseRefEndIndex,
    );

    //logExceptRelease("A: $prereleaseRefSubstring");

    final List<String> elements = prereleaseRefSubstring.split("/");

    logExceptRelease("${elements[2]}: ^${elements[4]}");

    return Dependency(
      name: elements[2],
      versionConstraint: VersionConstraint.parse("^${elements[4]}"),
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

  bool isSame(Object? other) =>
      ((other is Dependency) && (other.name == name)) ||
      ((other is UpdateInformation) && isSame(other.current));

  bool operator >(Object other) {
    assert(other is! UpdateInformation);
    assert(isSame(other));
    return ((other is Dependency) &&
            (versionConstraint.version > other.versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (versionConstraint.version > other.version)) ||
        ((other is Version) && versionConstraint.version > other);
  }

  bool operator <(Object other) {
    assert(other is! UpdateInformation);
    assert(isSame(other));
    return ((other is Dependency) &&
            (versionConstraint.version < other.versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (versionConstraint.version < other.version)) ||
        ((other is Version) && versionConstraint.version < other);
  }

  bool operator >=(Object other) {
    assert(other is! UpdateInformation);
    assert(isSame(other));
    return ((other is Dependency) &&
            (versionConstraint.version >= other.versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (versionConstraint.version >= other.version)) ||
        ((other is Version) && versionConstraint.version >= other);
  }

  bool operator <=(Object other) {
    assert(other is! UpdateInformation);
    assert(isSame(other));
    return ((other is Dependency) &&
            (versionConstraint.version <= other.versionConstraint.version)) ||
        ((other is VersionConstraint) &&
            (versionConstraint.version <= other.version)) ||
        ((other is Version) && versionConstraint.version <= other);
  }

  bool allows(Object? other) {
    assert(other is! UpdateInformation);
    return ((other is Dependency) &&
            isSame(other) &&
            versionConstraint.allowsAny(other.versionConstraint)) ||
        ((other is VersionConstraint) && versionConstraint.allowsAny(other)) ||
        ((other is Version) && versionConstraint.allows(other));
  }
}
