import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pushed/pushed.dart';

void main() {
  late GetIt getIt;
  late RouteScopeManager scopeManager;

  setUp(() {
    getIt = GetIt.instance;
    scopeManager = RouteScopeManager();
  });

  tearDown(() async {
    // ignore: unawaited_futures
    getIt.reset();
    await scopeManager.resetAllScopes();
  });

  group('GoRouterScopeExtension', () {
    group('scopeManager getter', () {
      test('returns RouteScopeManager instance', () {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        expect(router.scopeManager, isNotNull);
        expect(router.scopeManager, isA<RouteScopeManager>());
      });

      test('returns same instance as global manager', () {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        expect(router.scopeManager, same(RouteScopeManager()));
      });
    });

    group('activeScopeCount', () {
      test('returns 0 when no scopes are active', () {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        expect(router.activeScopeCount, 0);
      });

      test('returns correct count when scopes are active', () async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        await scopeManager.createRouteScope(
          const ScopedRouteConfig(routePath: '/test1'),
        );
        expect(router.activeScopeCount, 1);

        await scopeManager.createRouteScope(
          const ScopedRouteConfig(routePath: '/test2'),
        );
        expect(router.activeScopeCount, 2);
      });
    });

    group('activeScopes getter', () {
      test('returns empty list when no scopes active', () {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        expect(router.activeScopes, isEmpty);
      });

      test('returns list of active scopes', () async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/test1',
            scopeName: 'scope1',
          ),
        );
        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/test2',
            scopeName: 'scope2',
          ),
        );

        expect(router.activeScopes, contains('scope1'));
        expect(router.activeScopes, contains('scope2'));
        expect(router.activeScopes.length, 2);
      });
    });

    group('currentScope getter', () {
      test('returns null when no scopes active', () {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        expect(router.currentScope, isNull);
      });

      test('returns most recent scope', () async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/test1',
            scopeName: 'scope1',
          ),
        );
        expect(router.currentScope, 'scope1');

        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/test2',
            scopeName: 'scope2',
          ),
        );
        expect(router.currentScope, 'scope2');
      });
    });

    group('hasActiveScope', () {
      test('returns true for active scope', () async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/test',
            scopeName: 'active_scope',
          ),
        );

        expect(router.hasActiveScope('active_scope'), true);
      });

      test('returns false for inactive scope', () {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        expect(router.hasActiveScope('nonexistent'), false);
      });
    });

    group('getActiveScopes', () {
      test('returns empty list when no scopes active', () {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        expect(router.getActiveScopes(), isEmpty);
      });

      test('returns list of active scopes', () async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/test1',
            scopeName: 'scope1',
          ),
        );
        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/test2',
            scopeName: 'scope2',
          ),
        );

        final scopes = router.getActiveScopes();
        expect(scopes, contains('scope1'));
        expect(scopes, contains('scope2'));
        expect(scopes.length, 2);
      });
    });

    group('resetAllScopes', () {
      test('clears all active scopes', () async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/test1',
            scopeName: 'scope1',
          ),
        );
        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/test2',
            scopeName: 'scope2',
          ),
        );

        expect(router.activeScopeCount, 2);

        await router.resetAllScopes();

        expect(router.activeScopeCount, 0);
        expect(router.activeScopes, isEmpty);
      });

      test('handles reset when no scopes exist', () async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: _dummyBuilder,
            ),
          ],
        );

        expect(router.activeScopeCount, 0);

        await router.resetAllScopes();

        expect(router.activeScopeCount, 0);
      });
    });

    group('integration tests', () {
      test('all getters work together correctly', () async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: _dummyBuilder,
            ),
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: _dummyBuilder,
            ),
          ],
        );

        expect(router.activeScopeCount, 0);
        expect(router.activeScopes, isEmpty);
        expect(router.currentScope, isNull);

        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/home',
            scopeName: 'home_scope',
          ),
        );
        expect(router.activeScopeCount, 1);
        expect(router.currentScope, 'home_scope');
        expect(router.hasActiveScope('home_scope'), true);

        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/dashboard',
            scopeName: 'dashboard_scope',
          ),
        );
        expect(router.activeScopeCount, 2);
        expect(router.currentScope, 'dashboard_scope');

        final scopes = router.getActiveScopes();
        expect(scopes, contains('home_scope'));
        expect(scopes, contains('dashboard_scope'));

        await router.resetAllScopes();

        expect(router.activeScopeCount, 0);
        expect(router.currentScope, isNull);
        expect(router.activeScopes, isEmpty);
      });
    });
  });
}

Widget _dummyBuilder(BuildContext context, GoRouterState state) =>
    const Scaffold();
