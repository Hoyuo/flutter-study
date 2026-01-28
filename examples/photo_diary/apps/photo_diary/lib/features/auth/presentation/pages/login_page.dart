// Re-export the actual implementation from the auth package.
//
// The router (app_router.dart) imports LoginPage from 'package:auth/auth.dart',
// so this local file is not used. It's kept for structural consistency.

export 'package:auth/presentation/pages/login_page.dart';
