part of structures;

enum DependencyType {
  dependency,
  devDependency;

  String get pubspecName {
    switch (this) {
      case DependencyType.dependency:
        return "dependencies";
      case DependencyType.devDependency:
        return "dev_dependencies";
    }
  }

  String get prettyName {
    switch (this) {
      case DependencyType.dependency:
        return "Dependencies";
      case DependencyType.devDependency:
        return "Dev Dependencies";
    }
  }

  String get typeName {
    switch (this) {
      case DependencyType.dependency:
        return "Dependency";
      case DependencyType.devDependency:
        return "Dev Dependency";
    }
  }
}
