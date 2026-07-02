import 'package:flutter/material.dart';

import 'app.dart';
import 'config/dependency_injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const OffspringTrackerApp());
}
