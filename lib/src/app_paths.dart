import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:xdg_directories/xdg_directories.dart' as xdg;

Future<String> getAppMediaDir({
  required String appId,
  required String appName,
}) async {
  if (Platform.isAndroid) {
    String androidPath;
    final externalPath = await getExternalStorageDirectory();
    if (externalPath != null) {
      androidPath = externalPath.path;
    } else {
      // If media folder isn't allowed, use the data folder
      androidPath = "/storage/emulated/0/Android/$appId/files";
    }
    final mediaFolder = p.join(androidPath, "media");
    await Directory(mediaFolder).create(recursive: true);
    return mediaFolder;
  } else {
    final dataPath = p.join(
      await getAppPrivateDataDir(appName: appName),
      "media",
    );
    await Directory(dataPath).create(recursive: true);
    return dataPath;
  }
}

Future<String> getAppPrivateDataDir({required String appName}) async {
  // Documentation says that this directory shouldn't be used for storing
  // user generated data, but this structure makes sense for me
  if (Platform.isLinux) {
    // By default in Linux, getAppSupportDirectory uses the AppId to name the
    // folder, but thats not the usual way in Linux, so I'm gonna use the app
    // name instead as the folder name
    final path = p.join(xdg.dataHome.path, appName);
    await Directory(path).create();
    return path;
  } else {
    return (await getApplicationSupportDirectory()).path;
  }
}

Future<String> getAppCacheDir() async {
  return (await getApplicationCacheDirectory()).path;
}

Future<String> getAppId() async {
  final appSupportDir = await getApplicationSupportDirectory();
  return p.basename(appSupportDir.parent.path);
}
