import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_utilities/flutter_utilities.dart';

enum WSMDepth {
  light,
  medium,
  deep,
}

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
    workStatusMesageNotifier.value = message.message;
    return true;
  }
  return false;
}
