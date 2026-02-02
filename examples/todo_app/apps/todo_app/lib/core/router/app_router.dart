import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/task/presentation/pages/task_list_page.dart';
import '../../features/task/presentation/pages/all_tasks_page.dart';
import '../../features/task/presentation/pages/task_edit_page.dart';
import '../../features/category/presentation/pages/category_management_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/tasks',
    routes: [
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        pageBuilder: (context, state) => const MaterialPage(
          child: TaskListPage(),
        ),
        routes: [
          GoRoute(
            path: 'all',
            name: 'all-tasks',
            pageBuilder: (context, state) => const MaterialPage(
              child: AllTasksPage(),
            ),
          ),
          GoRoute(
            path: 'new',
            name: 'new-task',
            pageBuilder: (context, state) => const MaterialPage(
              child: TaskEditPage(),
            ),
          ),
          GoRoute(
            path: ':id/edit',
            name: 'edit-task',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return MaterialPage(
                child: TaskEditPage(taskId: id),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/categories',
        name: 'categories',
        pageBuilder: (context, state) => const MaterialPage(
          child: CategoryManagementPage(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => const MaterialPage(
          child: SettingsPage(),
        ),
      ),
    ],
  );
}
