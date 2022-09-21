part of structures;

enum UpdateType {
  /// The current version is the lastest version. There is no update.
  noUpdate,

  /// There is an update.
  update,

  /// There is a major update.
  majorUpdate,

  /// The current version is higher than the latest version checked.
  higher,

  /// Unknown update status. Something wrong might have been happened.
  unknown;

  String get displayName {
    switch (this) {
      case noUpdate:
        return "Latest";
      case update:
        return "UPDATE";
      case majorUpdate:
        return "MAJOR UPDATE";
      case higher:
        return "Higher";
      case unknown:
        return "Unknown";
    }
  }

  String get description {
    switch (this) {
      case noUpdate:
        return "There is no update. The current version is the lastest version.";
      case update:
        return "There is an update.";
      case majorUpdate:
        return "There is a major update. It may contain breaking changes, so updating the codes might be needed.";
      case higher:
        return "The current version is higher than the latest version checked.";
      case unknown:
        return "Unknown update status. Something wrong might have been happened with checking.";
    }
  }

  static UpdateType getUpdateType(Dependency current, Dependency? other) {
    if ((other == null) || (other == current)) {
      return noUpdate;
    }
    
    if (other > current) {
      if (other.allows(current)) {
        return update;
      }
      return majorUpdate;
    }
    if (other < current) {
      return higher;
    }
    return unknown;
  }

  bool get shouldUpdate {
    switch (this) {
      case noUpdate:
        return false;
      case update:
        return true;
      case majorUpdate:
        return false;
      case higher:
        return false;
      case unknown:
        return true;
    }
  }
}
