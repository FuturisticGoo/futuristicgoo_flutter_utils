import 'dart:async';

sealed class ProgressType {
  const ProgressType();
}

abstract class ProgressUpdate extends ProgressType {
  final num finished;
  final num? total;
  const ProgressUpdate({
    required this.finished,
    required this.total,
  });
  double get percentageFinished => total == null ? 0 : finished / total!;
}

abstract class ProgressFinished extends ProgressType {}

abstract class ProgressError extends ProgressType {}

/// This global stream-sink pair allows to get progress information for long
/// running tasks, without having to shoehorn that into our logic. It is
/// general enough that it can be used for most tasks.
class GlobalProgressPipe {
  final StreamController<ProgressType> _streamController =
      StreamController.broadcast();
  static GlobalProgressPipe instance = GlobalProgressPipe._();

  GlobalProgressPipe._();

  Future<void> dispose() async {
    await _streamController.close();
  }

  /// Future completes when the [ProgressFinished] event is encountered
  Future<void> subscribeToProgress<U extends ProgressUpdate,
      F extends ProgressFinished, E extends ProgressError>({
    required void Function(U progressUpdate) onUpdate,
    required void Function(F progressFinish) onFinish,
    void Function(E progressError)? onError,
  }) async {
    streamLoop:
    await for (final event in _streamController.stream) {
      switch (event) {
        case U():
          onUpdate(event);
        case F():
          onFinish(event);
          break streamLoop;
        case E():
          if (onError != null) {
            onError(event);
          }
        default:
          continue;
      }
    }
  }

  /// Add a [ProgressType] event to the stream.
  /// Can be an [ProgressUpdate] or [ProgressFinished] event.
  void addProgress({required ProgressType progressEvent}) {
    _streamController.add(progressEvent);
  }
}
