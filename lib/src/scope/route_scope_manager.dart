import 'package:get_it/get_it.dart';
import 'package:pushed/src/core/models/scoped_route_config.dart';

/// Manages route-scoped dependencies using get_it scopes.
///
/// Responsible for creating and disposing scopes associated with routes.
/// Coordinates with get_it to push/pop scopes when navigating.
class RouteScopeManager {
  /// Returns the singleton instance.
  factory RouteScopeManager() => _instance;

  RouteScopeManager._internal();

  /// Singleton instance of [RouteScopeManager].
  static final RouteScopeManager _instance = RouteScopeManager._internal();

  final GetIt _getIt = GetIt.instance;
  final List<String> _activeScopes = [];

  /// Gets the list of currently active scope names.
  List<String> get activeScopes => List.unmodifiable(_activeScopes);

  /// Creates a new scope for a route and registers dependencies.
  ///
  /// Pushes a new scope in get_it and executes the [ScopedRouteConfig.scopeInitializer]
  /// to register route-specific dependencies.
  ///
  /// Throws [ArgumentError] if a scope with the same name already exists.
  Future<void> createRouteScope(ScopedRouteConfig config) async {
    final effectiveName = config.effectiveScopeName;

    if (_activeScopes.contains(effectiveName)) {
      throw ArgumentError('Scope "$effectiveName" already exists');
    }

    try {
      _getIt.pushNewScope(
        scopeName: effectiveName,
        init: config.scopeInitializer,
        isFinal: config.isFinal,
      );
      _activeScopes.add(effectiveName);
    } catch (e) {
      rethrow;
    }
  }

  /// Disposes a route scope and cleans up its dependencies.
  ///
  /// Calls the [ScopedRouteConfig.scopeDisposer] if provided, then pops the scope
  /// from get_it.
  ///
  /// Returns false if scope doesn't exist.
  Future<bool> disposeRouteScope(ScopedRouteConfig config) async {
    final effectiveName = config.effectiveScopeName;

    if (!_activeScopes.contains(effectiveName)) {
      return false;
    }

    try {
      if (config.scopeDisposer != null) {
        await config.scopeDisposer!(_getIt);
      }

      await _getIt.popScope();
      _activeScopes.remove(effectiveName);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if a scope with the given name exists.
  bool hasScope(String scopeName) => _activeScopes.contains(scopeName);

  /// Gets a scope by name.
  ///
  /// Returns the scope name if it exists, otherwise null.
  String? getScope(String scopeName) {
    if (_activeScopes.contains(scopeName)) {
      return scopeName;
    }
    return null;
  }

  /// Resets all scopes.
  ///
  /// Clears all active scopes. Use with caution.
  Future<void> resetAllScopes({bool dispose = true}) async {
    // Pop scopes in reverse order (most recent first)
    while (_activeScopes.isNotEmpty) {
      if (dispose) {
        try {
          await _getIt.popScope();
        } catch (e) {
          // If we can't pop (e.g., already on base scope), just clear the list
          break;
        }
      }
      _activeScopes.removeLast();
    }
  }

  /// Returns the currently active scope name.
  ///
  /// Returns the most recently created scope name, or null if no scopes exist.
  String? get currentScope =>
      _activeScopes.isNotEmpty ? _activeScopes.last : null;

  /// Returns the number of active scopes.
  int get activeScopeCount => _activeScopes.length;
}
