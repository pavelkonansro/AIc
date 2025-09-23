import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('🚀 AIc запускается в простом режиме для диагностики...');
  
  runApp(const ProviderScope(child: AicApp()));
}