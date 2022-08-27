part of structures;

class StatusMessage extends Equatable {
  final String message;
  final WSMDepth depth;

  const StatusMessage({
    required this.message,
    required this.depth,
  });

  @override
  List<Object?> get props => [
        message,
        depth,
      ];
}

bool setStatusMessage({
  required StatusMessage message,
  required WSMDepth yourDepth,
  required ValueNotifier<String?> workStatusMesageNotifier,
}) {
  if (yourDepth.index >= message.depth.index) {
    logExceptRelease("Setting status message: ${message.message}");
    try {
      workStatusMesageNotifier.value = message.message;
    } catch (e, _) {
      log(
        "Error setting status message: $e",
        error: e,
        //stackTrace: s,
      );
      return false;
    }

    return true;
  }
  return false;
}
