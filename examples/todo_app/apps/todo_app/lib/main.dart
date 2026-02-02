import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task/task.dart';
import 'package:category/category.dart';

import 'app.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());

  // Setup dependency injection
  await setupDependencyInjection();

  runApp(const TodoApp());
}
