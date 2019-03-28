import 'package:path_provider/path_provider.dart';

class FileUtils {

  static Future<String> getPathByName(String fileName) async {
     return (await getExternalStorageDirectory()).path + "/flutter_discovery/" + fileName;
  }

}