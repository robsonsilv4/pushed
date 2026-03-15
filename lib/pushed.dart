/// Scoped dependencies for go_router routes using get_it.
///
/// This package enables automatic dependency injection and cleanup for
/// different routes using get_it scopes. Each route can have its own
/// isolated set of dependencies that are automatically cleaned up when
/// the route is popped.
library pushed;

// Export public API
export 'src/core/models/scoped_route_config.dart';
export 'src/scope/route_scope_manager.dart';
