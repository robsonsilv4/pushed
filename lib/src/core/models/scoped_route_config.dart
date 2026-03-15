import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';

/// Type definition for scope initializer function.
///
/// Called when a new scope is created to register dependencies.
typedef ScopeInitializer = void Function(GetIt getIt);

/// Type definition for scope disposer function.
///
/// Called when a scope is being disposed to clean up resources.
typedef ScopeDisposer = Future<void> Function(GetIt getIt);

/// Configuration for a route with scoped dependencies.
///
/// Defines how dependencies should be registered and cleaned up for a
/// specific route.
class ScopedRouteConfig extends Equatable {
  /// Creates a new [ScopedRouteConfig].
  const ScopedRouteConfig({
    required this.routePath,
    this.scopeInitializer,
    this.scopeDisposer,
    this.scopeName,
    this.isFinal = false,
  });

  /// The path of the route.
  final String routePath;

  /// Optional custom name for this scope.
  ///
  /// If not provided, [routePath] will be used as the scope name.
  final String? scopeName;

  /// Function to initialize the scope with dependencies.
  final ScopeInitializer? scopeInitializer;

  /// Function to dispose the scope and clean up resources.
  final ScopeDisposer? scopeDisposer;

  /// Whether this scope is final and cannot register new objects after creation.
  ///
  /// If true, all objects must be registered in [scopeInitializer].
  final bool isFinal;

  /// Returns the effective scope name.
  ///
  /// Uses [scopeName] if provided, otherwise returns [routePath].
  String get effectiveScopeName => scopeName ?? routePath;

  @override
  String toString() =>
      'ScopedRouteConfig(routePath: $routePath, scopeName: $scopeName, '
      'isFinal: $isFinal)';

  @override
  List<Object?> get props => [
        routePath,
        scopeName,
        scopeInitializer,
        scopeDisposer,
        isFinal,
      ];
}
