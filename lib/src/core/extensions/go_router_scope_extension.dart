import 'package:go_router/go_router.dart';
import 'package:pushed/src/scope/route_scope_manager.dart';

/// Extension on [GoRouter] to add scope management helpers.
///
/// Provides convenient methods to query and manage route scopes
/// within the router configuration.
extension GoRouterScopeExtension on GoRouter {
  /// Gets the [RouteScopeManager] instance.
  ///
  /// Returns the singleton [RouteScopeManager] used to manage all
  /// route scopes throughout the application.
  ///
  /// Example:
  /// ```dart
  /// final scopeManager = router.scopeManager;
  /// final activeScopes = scopeManager.activeScopes;
  /// ```
  RouteScopeManager get scopeManager => RouteScopeManager();

  /// Gets the number of currently active route scopes.
  ///
  /// Returns the count of active scopes managed by the router's
  /// scope manager.
  ///
  /// Example:
  /// ```dart
  /// final count = router.activeScopeCount;
  /// print('Active scopes: $count');
  /// ```
  int get activeScopeCount => scopeManager.activeScopeCount;

  /// Gets the list of all currently active scope names.
  ///
  /// Returns an immutable list of scope names that are currently active.
  /// The order represents the stack of scopes (most recent last).
  ///
  /// Example:
  /// ```dart
  /// final scopes = router.activeScopes;
  /// for (final scope in scopes) {
  ///   print('Active scope: $scope');
  /// }
  /// ```
  List<String> get activeScopes => scopeManager.activeScopes;

  /// Gets the currently active scope name.
  ///
  /// Returns the name of the most recently created scope, or null
  /// if no scopes are currently active.
  ///
  /// Example:
  /// ```dart
  /// final currentScope = router.currentScope;
  /// if (currentScope != null) {
  ///   print('Current scope: $currentScope');
  /// }
  /// ```
  String? get currentScope => scopeManager.currentScope;

  /// Checks if a specific scope is currently active.
  ///
  /// Returns true if the scope with the given name is active,
  /// false otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (router.hasActiveScope('product_details')) {
  ///   // Scope is active
  /// }
  /// ```
  bool hasActiveScope(String scopeName) => scopeManager.hasScope(scopeName);

  /// Gets all currently active scope names.
  ///
  /// Returns an unmodifiable list of all active scope names.
  /// This is an alias for [activeScopes].
  ///
  /// Example:
  /// ```dart
  /// final scopes = router.getActiveScopes();
  /// for (final scope in scopes) {
  ///   print('Active scope: $scope');
  /// }
  /// ```
  List<String> getActiveScopes() => scopeManager.activeScopes;

  /// Resets all active scopes and their dependencies.
  ///
  /// This method is useful for testing or when you need to perform
  /// a complete reset of all scope state. It disposes all active scopes
  /// and their dependencies.
  ///
  /// **Warning:** Use with caution as this will dispose all active dependencies.
  ///
  /// Example:
  /// ```dart
  /// // During logout or testing
  /// await router.resetAllScopes();
  /// ```
  Future<void> resetAllScopes() async {
    await scopeManager.resetAllScopes();
  }
}
