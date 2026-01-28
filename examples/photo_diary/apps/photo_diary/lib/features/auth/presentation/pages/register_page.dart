// Re-export the actual implementation from the auth package.
//
// The router (app_router.dart) imports RegisterPage from 'package:auth/auth.dart',
// so this local file is not used. It's kept for structural consistency.
//
// Note: The package version includes the displayName field that was missing
// in the previous local implementation.

export 'package:auth/presentation/pages/register_page.dart';
