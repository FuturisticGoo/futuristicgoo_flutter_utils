import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pick_or_save/pick_or_save.dart';

final class NoSaveFilePickedException {}

abstract class CrossFileWriter {
  Future<void> writeBytes({required Uint8List bytes});
  Future<void> write({required Object object});
  Future<void> close();
  const CrossFileWriter();
  static Future<CrossFileWriter> openFileForWriting({
    required String fileName,
    required String cacheDirectory,
  }) async {
    if (Platform.isAndroid) {
      return _AndroidFileWriter.openFileForWriting(
        fileName: fileName,
        cacheDirectory: cacheDirectory,
      );
    } else if (Platform.isLinux || Platform.isWindows) {
      return _DesktopFileWriter.openFileForWriting(fileName: fileName);
    } else {
      throw UnsupportedError("Apple devices not supported");
    }
  }
}

class _DesktopFileWriter implements CrossFileWriter {
  final IOSink ioSink;
  const _DesktopFileWriter({
    required this.ioSink,
  });

  static Future<_DesktopFileWriter> openFileForWriting({
    required String fileName,
  }) async {
    final filePath = await FilePicker.platform.saveFile(fileName: fileName);
    if (filePath == null) {
      throw NoSaveFilePickedException();
    } else {
      final ioSink = File(filePath).openWrite(mode: FileMode.writeOnly);
      return _DesktopFileWriter(ioSink: ioSink);
    }
  }

  @override
  Future<void> writeBytes({required Uint8List bytes}) async {
    ioSink.add(bytes);
  }

  @override
  Future<void> write({required Object object}) async {
    ioSink.write(object);
  }

  @override
  Future<void> close() async {
    await ioSink.flush();
    await ioSink.close();
  }
}

class _AndroidFileWriter implements CrossFileWriter {
  final File cacheOutputFile;
  final IOSink ioSink;
  const _AndroidFileWriter({
    required this.cacheOutputFile,
    required this.ioSink,
  });

  static Future<_AndroidFileWriter> openFileForWriting({
    required String fileName,
    required String cacheDirectory,
  }) async {
    final cacheOutputFile = File(p.join(cacheDirectory, fileName));
    final ioSink = cacheOutputFile.openWrite(
      mode: FileMode.writeOnly,
    );
    return _AndroidFileWriter(
      cacheOutputFile: cacheOutputFile,
      ioSink: ioSink,
    );
  }

  @override
  Future<void> writeBytes({required Uint8List bytes}) async {
    ioSink.add(bytes);
  }

  @override
  Future<void> write({required Object object}) async {
    ioSink.write(object);
  }

  @override
  Future<void> close() async {
    await ioSink.flush();
    await ioSink.close();
    final result = await PickOrSave().fileSaver(
      params: FileSaverParams(
        saveFiles: [
          SaveFileInfo(
            filePath: cacheOutputFile.path,
            fileName: p.basename(
              cacheOutputFile.path,
            ),
          ),
        ],
      ),
    );
    await cacheOutputFile.delete();
    if (result == null) {
      throw NoSaveFilePickedException();
    }
  }
}
