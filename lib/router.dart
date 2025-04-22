import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:labshare/ui/home.dart';
import 'package:labshare/ui/student.dart';
import 'package:labshare/ui/teacher.dart';

GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: <RouteBase>[
    GoRoute(
      name: "home",
      path: "/",
      pageBuilder:
          (context, state) => const NoTransitionPage(child: HomeScreen()),
    ),
    GoRoute(
      name: "teacher",
      path: "/teacher",
      pageBuilder:
          (context, state) => const NoTransitionPage(child: TeacherScreen()),
    ),

    GoRoute(
      name: "student",
      path: "/student",
      pageBuilder:
          (context, state) => const NoTransitionPage(child: StudentScreen()),
    ),
  ],
);
