import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pushed/src/core/models/scoped_route_config.dart';
import 'package:pushed/src/integration/scope_observer.dart';

/// Extension on [GoRoute] to add scope configuration support.
///
/// Allows routes to be configured with dependency initialization and
/// disposal callbacks that are managed by [ScopeObserver].
extension GoRouteScopeExtension on GoRoute {
  /// Registers this route with scope configuration on the provided observer.
  ///
  /// This method registers the route's scope metadata with the observer,
  /// which will then manage scope creation/disposal when the route is pushed/popped.
  ///
  /// Must be called during app initialization before navigation occurs.
  ///
  /// Example:
  /// ```dart
  /// final scopeObserver = ScopeObserver();
  ///
  /// GoRoute(
  ///   path: '/dashboard',
  ///   name: 'dashboard',
  ///   builder: (context, state) => DashboardPage(),
  /// ).withScope(
  ///   observer: scopeObserver,
  ///   scopeInitializer: (getIt) {
  ///     getIt.registerSingleton<DashboardService>(DashboardService());
  ///   },
  ///   scopeDisposer: (getIt) async {
  ///     final service = getIt<DashboardService>();
  ///     await service.cleanup();
  ///   },
  /// )
  /// ```
  void withScope({
    required ScopeObserver observer,
    void Function(GetIt)? scopeInitializer,
    Future<void> Function(GetIt)? scopeDisposer,
    String? scopeName,
    bool isFinal = false,
  }) {
    final routeName = name ?? path;

    final config = ScopedRouteConfig(
      routePath: path,
      scopeName: scopeName ?? routeName,
      scopeInitializer: scopeInitializer,
      scopeDisposer: scopeDisposer,
      isFinal: isFinal,
    );

    observer.registerRouteScope(routeName, config);
  }
}
