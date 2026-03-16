import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pushed/src/core/models/scoped_route_config.dart';
import 'package:pushed/src/integration/go_route_scope_extension.dart';
import 'package:pushed/src/scope/route_scope_manager.dart';

/// A [NavigatorObserver] that manages route-scoped dependencies.
///
/// This observer integrates with [RouteScopeManager] to automatically
/// create and dispose route scopes as routes are pushed, popped, or replaced.
///
/// Each route can have its own isolated set of dependencies that are
/// automatically initialized when the route is pushed and cleaned up
/// when the route is popped.
///
/// To use this observer with `go_router`, add it to the router:
/// ```dart
/// final scopeObserver = ScopeObserver();
///
/// GoRouter(
///   observers: [scopeObserver],
///   routes: [...],
/// )
/// ```
///
// ignore: comment_references
/// To attach scope configuration to routes, use [GoRoute.withScope]:
/// ```dart
/// GoRoute(
///   path: '/dashboard',
///   name: 'dashboard',
///   builder: (context, state) => DashboardPage(),
/// ).withScope(
///   observer: scopeObserver,
///   scopeInitializer: (getIt) {
///     getIt.registerSingleton<DashboardService>(DashboardService());
///   },
/// )
/// ```
class ScopeObserver extends NavigatorObserver {
  /// Creates a new [ScopeObserver] instance.
  ///
  /// The [scopeManager] defaults to the singleton [RouteScopeManager] instance
  /// if not provided. Set [enableLogging] to true to enable debug logging of
  /// scope operations.
  ScopeObserver({
    RouteScopeManager? scopeManager,
    this.enableLogging = false,
  }) : scopeManager = scopeManager ?? RouteScopeManager();

  /// The scope manager instance to use for managing scopes.
  /// Defaults to the singleton instance.
  final RouteScopeManager scopeManager;

  /// Whether to log scope operations (for debugging).
  final bool enableLogging;

  /// Maps route identifiers to their scope configurations.
  final Map<String, ScopedRouteConfig> _routeScopes = {};

  /// Tracks active route-to-scope mappings.
  final Map<String, String> _activeRouteScopes = {};

  /// Gets the number of registered route scopes.
  int get registeredScopeCount => _routeScopes.length;

  /// Gets the number of active route scopes.
  int get activeScopeCount => _activeRouteScopes.length;

  /// Gets all registered route names.
  List<String> get registeredRoutes => List.unmodifiable(_routeScopes.keys);

  /// Gets all active route scopes.
  List<String> get activeRoutes => List.unmodifiable(_activeRouteScopes.values);

  /// Registers a route scope configuration.
  ///
  /// This should be called before the route is navigated to, typically
  /// during app initialization or using the [GoRouteScopeExtension.withScope] extension.
  ///
  /// Throws [ArgumentError] if a scope is already registered for this route.
  void registerRouteScope(
    String routeName,
    ScopedRouteConfig config,
  ) {
    if (_routeScopes.containsKey(routeName)) {
      throw ArgumentError(
        'Route scope already registered for "$routeName"',
      );
    }

    _routeScopes[routeName] = config;

    if (enableLogging) {
      debugPrint('[ScopeObserver] Registered scope for route: $routeName');
    }
  }

  /// Unregisters a route scope configuration.
  ///
  /// Returns true if a scope was unregistered, false otherwise.
  bool unregisterRouteScope(String routeName) {
    final removed = _routeScopes.remove(routeName) != null;

    if (removed && enableLogging) {
      debugPrint('[ScopeObserver] Unregistered scope for route: $routeName');
    }

    return removed;
  }

  /// Gets the scope configuration for a route.
  ScopedRouteConfig? getScopeConfig(String routeName) {
    return _routeScopes[routeName];
  }

  /// Checks if a route has a registered scope.
  bool hasRegisteredScope(String routeName) {
    return _routeScopes.containsKey(routeName);
  }

  /// Checks if a route has an active scope.
  bool hasActiveScope(String routeName) {
    return _activeRouteScopes.containsKey(routeName);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRoutePush(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      _handleRouteDispose(oldRoute);
    }
    if (newRoute != null) {
      _handleRoutePush(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _handleRouteDispose(route);
  }

  /// Handles scope creation when a route is pushed.
  void _handleRoutePush(Route<dynamic> route) {
    final routeName = route.settings.name;
    if (routeName == null || routeName.isEmpty) {
      if (enableLogging) {
        debugPrint(
          '[ScopeObserver] Route has no name, skipping scope creation',
        );
      }
      return;
    }

    _createScopeForRoute(routeName);
  }

  /// Handles scope disposal when a route is disposed/popped.
  void _handleRouteDispose(Route<dynamic> route) {
    final routeName = route.settings.name;
    if (routeName == null || routeName.isEmpty) {
      return;
    }

    _disposeScopeForRoute(routeName);
  }

  /// Creates a scope for the given route if it has a registered configuration.
  void _createScopeForRoute(String routeName) {
    final config = _routeScopes[routeName];
    if (config == null) {
      if (enableLogging) {
        debugPrint(
          '[ScopeObserver] No scope configuration for route: $routeName',
        );
      }
      return;
    }

    if (enableLogging) {
      debugPrint(
        '[ScopeObserver] Creating scope for route: $routeName '
        '(scope: ${config.effectiveScopeName})',
      );
    }

    unawaited(
      scopeManager.createRouteScope(config).then((_) {
        _activeRouteScopes[routeName] = config.effectiveScopeName;

        if (enableLogging) {
          debugPrint(
            '[ScopeObserver] Scope created successfully for route: $routeName',
          );
        }
      }).catchError(
        (Object error, StackTrace stackTrace) {
          debugPrint(
            '[ScopeObserver] Error creating scope for route "$routeName": $error',
          );
          if (kDebugMode) {
            debugPrintStack(stackTrace: stackTrace);
          }
        },
      ),
    );
  }

  /// Disposes the scope for the given route.
  void _disposeScopeForRoute(String routeName) {
    final config = _routeScopes[routeName];
    if (config == null) {
      return;
    }

    if (enableLogging) {
      debugPrint(
        '[ScopeObserver] Disposing scope for route: $routeName '
        '(scope: ${config.effectiveScopeName})',
      );
    }

    unawaited(
      scopeManager.disposeRouteScope(config).then((disposed) {
        if (disposed) {
          _activeRouteScopes.remove(routeName);

          if (enableLogging) {
            debugPrint(
              '[ScopeObserver] Scope disposed successfully for route: $routeName',
            );
          }
        } else if (enableLogging) {
          debugPrint(
            '[ScopeObserver] Scope was not active for route: $routeName',
          );
        }
      }).catchError(
        (Object error, StackTrace stackTrace) {
          debugPrint(
            '[ScopeObserver] Error disposing scope for route "$routeName": $error',
          );
          if (kDebugMode) {
            debugPrintStack(stackTrace: stackTrace);
          }
        },
      ),
    );
  }

  /// Resets all tracked scopes and configurations.
  ///
  /// This is useful for testing or when you need a clean state.
  Future<void> reset() async {
    if (enableLogging) {
      debugPrint(
        '[ScopeObserver] Resetting all tracked scopes '
        '(active: ${_activeRouteScopes.length})',
      );
    }

    _activeRouteScopes.clear();
    _routeScopes.clear();
    await scopeManager.resetAllScopes();

    if (enableLogging) {
      debugPrint('[ScopeObserver] Reset complete');
    }
  }
}
