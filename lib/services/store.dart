import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';

class ObjectBox {
  static late Store store;

  static init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    store = await openStore(directory: p.join(docsDir.path, "RestLite"));
  }
}
