import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pushed/pushed.dart';

// Test services
class _UserService {
  _UserService({required this.userId});

  final String userId;
  bool disposed = false;

  Future<void> dispose() async {
    disposed = true;
  }
}

class _ProductService {
  final List<String> products = [];
  bool disposed = false;

  void addProduct(String product) {
    products.add(product);
  }

  Future<void> dispose() async {
    disposed = true;
  }
}

class _OrderService {
  final List<String> orders = [];
  bool disposed = false;

  void addOrder(String order) {
    orders.add(order);
  }

  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  late GetIt getIt;
  late RouteScopeManager scopeManager;
  late ScopeObserver scopeObserver;

  setUp(() {
    getIt = GetIt.instance;
    scopeManager = RouteScopeManager();
    scopeObserver = ScopeObserver(scopeManager: scopeManager);
  });

  tearDown(() async {
    await scopeObserver.reset();
    await scopeObserver.reset();
  });

  group('End-to-End Integration Tests', () {
    group('Single route scope lifecycle', () {
      test('creates scope on route push and disposes on pop', () async {
        final userService = _UserService(userId: 'user123');

        await scopeManager.createRouteScope(
          ScopedRouteConfig(
            routePath: '/home',
            scopeName: 'home_scope',
            scopeInitializer: (getIt) {
              getIt.registerSingleton<_UserService>(userService);
            },
            scopeDisposer: (getIt) async {
              final service = getIt<_UserService>();
              await service.dispose();
            },
          ),
        );

        expect(scopeManager.activeScopeCount, 1);
        expect(userService.disposed, false);

        final user = getIt<_UserService>();
        expect(user.userId, 'user123');

        await scopeManager.disposeRouteScope(
          ScopedRouteConfig(
            routePath: '/home',
            scopeName: 'home_scope',
            scopeDisposer: (getIt) async {
              final service = getIt<_UserService>();
              await service.dispose();
            },
          ),
        );

        expect(scopeManager.activeScopeCount, 0);
        expect(userService.disposed, true);
      });
    });

    group('Multiple route scopes', () {
      test('manages multiple scopes with different dependencies', () async {
        final userService = _UserService(userId: 'user1');
        final productService = _ProductService();
        final orderService = _OrderService();

        // Push home scope
        await scopeManager.createRouteScope(
          ScopedRouteConfig(
            routePath: '/home',
            scopeName: 'home_scope',
            scopeInitializer: (getIt) {
              getIt.registerSingleton<_UserService>(userService);
            },
            scopeDisposer: (getIt) async {
              await getIt<_UserService>().dispose();
            },
          ),
        );

        expect(scopeManager.activeScopeCount, 1);
        expect(scopeManager.currentScope, 'home_scope');
        expect(getIt<_UserService>().userId, 'user1');

        // Push products scope
        await scopeManager.createRouteScope(
          ScopedRouteConfig(
            routePath: '/products',
            scopeName: 'products_scope',
            scopeInitializer: (getIt) {
              getIt.registerSingleton<_ProductService>(productService);
            },
            scopeDisposer: (getIt) async {
              await getIt<_ProductService>().dispose();
            },
          ),
        );

        expect(scopeManager.activeScopeCount, 2);
        expect(scopeManager.currentScope, 'products_scope');
        expect(getIt<_ProductService>().products, isEmpty);

        // Push orders scope
        await scopeManager.createRouteScope(
          ScopedRouteConfig(
            routePath: '/orders',
            scopeName: 'orders_scope',
            scopeInitializer: (getIt) {
              getIt.registerSingleton<_OrderService>(orderService);
            },
            scopeDisposer: (getIt) async {
              await getIt<_OrderService>().dispose();
            },
          ),
        );

        expect(scopeManager.activeScopeCount, 3);
        expect(scopeManager.currentScope, 'orders_scope');
        expect(scopeManager.activeScopes.length, 3);

        // Pop orders scope
        await scopeManager.disposeRouteScope(
          ScopedRouteConfig(
            routePath: '/orders',
            scopeName: 'orders_scope',
            scopeDisposer: (getIt) async {
              await getIt<_OrderService>().dispose();
            },
          ),
        );

        expect(scopeManager.activeScopeCount, 2);
        expect(scopeManager.currentScope, 'products_scope');
        expect(orderService.disposed, true);

        // Pop products scope
        await scopeManager.disposeRouteScope(
          ScopedRouteConfig(
            routePath: '/products',
            scopeName: 'products_scope',
            scopeDisposer: (getIt) async {
              await getIt<_ProductService>().dispose();
            },
          ),
        );

        expect(scopeManager.activeScopeCount, 1);
        expect(scopeManager.currentScope, 'home_scope');
        expect(productService.disposed, true);

        // Pop home scope
        await scopeManager.disposeRouteScope(
          ScopedRouteConfig(
            routePath: '/home',
            scopeName: 'home_scope',
            scopeDisposer: (getIt) async {
              await getIt<_UserService>().dispose();
            },
          ),
        );

        expect(scopeManager.activeScopeCount, 0);
        expect(scopeManager.currentScope, isNull);
        expect(userService.disposed, true);
      });
    });

    group('Scope initialization and disposal', () {
      test('executes initializer and disposer in correct order', () async {
        final executionOrder = <String>[];

        await scopeManager.createRouteScope(
          ScopedRouteConfig(
            routePath: '/test',
            scopeName: 'test_scope',
            scopeInitializer: (getIt) {
              executionOrder.add('init');
              getIt.registerSingleton<String>('test_value');
            },
            scopeDisposer: (getIt) async {
              executionOrder.add('dispose');
            },
          ),
        );

        expect(executionOrder, ['init']);
        expect(getIt<String>(), 'test_value');

        await scopeManager.disposeRouteScope(
          ScopedRouteConfig(
            routePath: '/test',
            scopeName: 'test_scope',
            scopeDisposer: (getIt) async {
              executionOrder.add('dispose');
            },
          ),
        );

        expect(executionOrder, ['init', 'dispose']);
      });

      test('handles missing disposer gracefully', () async {
        await scopeManager.createRouteScope(
          ScopedRouteConfig(
            routePath: '/test',
            scopeName: 'test_scope',
            scopeInitializer: (getIt) {
              getIt.registerSingleton<String>('test_value');
            },
          ),
        );

        expect(scopeManager.activeScopeCount, 1);

        // Dispose without disposer should not throw
        await scopeManager.disposeRouteScope(
          const ScopedRouteConfig(
            routePath: '/test',
            scopeName: 'test_scope',
          ),
        );

        expect(scopeManager.activeScopeCount, 0);
      });
    });

    group('Scope name uniqueness', () {
      test('prevents duplicate scope registration', () async {
        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/test',
            scopeName: 'unique_scope',
          ),
        );

        expect(
          () => scopeManager.createRouteScope(
            const ScopedRouteConfig(
              routePath: '/test2',
              scopeName: 'unique_scope',
            ),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Scope access', () {
      test('can access dependencies from active scope', () async {
        final userService = _UserService(userId: 'user123');

        await scopeManager.createRouteScope(
          ScopedRouteConfig(
            routePath: '/home',
            scopeName: 'home_scope',
            scopeInitializer: (getIt) {
              getIt.registerSingleton<_UserService>(userService);
            },
          ),
        );

        final retrieved = getIt<_UserService>();
        expect(retrieved.userId, 'user123');
        expect(identical(retrieved, userService), true);
      });

      test('scope has correct name', () async {
        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/test',
            scopeName: 'my_scope',
          ),
        );

        expect(scopeManager.currentScope, 'my_scope');
        expect(scopeManager.hasScope('my_scope'), true);
        expect(scopeManager.hasScope('other_scope'), false);
      });
    });

    group('Router integration', () {
      test('GoRouter extension queries scope state correctly', () async {
        final router = GoRouter(
          observers: [scopeObserver],
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(),
            ),
          ],
        );

        expect(router.activeScopeCount, 0);
        expect(router.currentScope, isNull);
        expect(router.activeScopes, isEmpty);

        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/test',
            scopeName: 'test_scope',
          ),
        );

        expect(router.activeScopeCount, 1);
        expect(router.currentScope, 'test_scope');
        expect(router.activeScopes, contains('test_scope'));
        expect(router.hasActiveScope('test_scope'), true);
        expect(router.getActiveScopes().length, 1);

        await router.resetAllScopes();

        expect(router.activeScopeCount, 0);
        expect(router.currentScope, isNull);
      });
    });

    group('Scope observer tracking', () {
      test('observer tracks scope registration', () {
        expect(scopeObserver.registeredScopeCount, 0);

        scopeObserver.registerRouteScope(
          'home',
          const ScopedRouteConfig(
            routePath: '/home',
            scopeName: 'home_scope',
          ),
        );

        expect(scopeObserver.registeredScopeCount, 1);
        expect(scopeObserver.hasRegisteredScope('home'), true);
      });
    });

    group('Complex navigation scenarios', () {
      test('handles rapid scope creation and disposal', () async {
        for (var i = 0; i < 10; i++) {
          await scopeManager.createRouteScope(
            ScopedRouteConfig(
              routePath: '/route$i',
              scopeName: 'scope$i',
              scopeInitializer: (getIt) {
                getIt.registerSingleton<int>(i);
              },
            ),
          );
        }

        expect(scopeManager.activeScopeCount, 10);

        for (var i = 9; i >= 0; i--) {
          await scopeManager.disposeRouteScope(
            ScopedRouteConfig(
              routePath: '/route$i',
              scopeName: 'scope$i',
            ),
          );
          expect(scopeManager.activeScopeCount, i);
        }

        expect(scopeManager.activeScopeCount, 0);
      });

      test('handles mixed navigation patterns', () async {
        // Push home
        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/home',
            scopeName: 'home_scope',
          ),
        );
        expect(scopeManager.activeScopeCount, 1);

        // Push products
        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/products',
            scopeName: 'products_scope',
          ),
        );
        expect(scopeManager.activeScopeCount, 2);

        // Push details
        await scopeManager.createRouteScope(
          const ScopedRouteConfig(
            routePath: '/products/details',
            scopeName: 'details_scope',
          ),
        );
        expect(scopeManager.activeScopeCount, 3);

        // Pop details
        await scopeManager.disposeRouteScope(
          const ScopedRouteConfig(
            routePath: '/products/details',
            scopeName: 'details_scope',
          ),
        );
        expect(scopeManager.activeScopeCount, 2);

        // Pop products
        await scopeManager.disposeRouteScope(
          const ScopedRouteConfig(
            routePath: '/products',
            scopeName: 'products_scope',
          ),
        );
        expect(scopeManager.activeScopeCount, 1);

        // Still on home
        expect(scopeManager.currentScope, 'home_scope');

        // Pop home
        await scopeManager.disposeRouteScope(
          const ScopedRouteConfig(
            routePath: '/home',
            scopeName: 'home_scope',
          ),
        );
        expect(scopeManager.activeScopeCount, 0);
      });
    });

    group('Error handling', () {
      test('handles unregistered scope disposal gracefully', () async {
        expect(scopeManager.activeScopeCount, 0);

        final disposed = await scopeManager.disposeRouteScope(
          const ScopedRouteConfig(
            routePath: '/nonexistent',
            scopeName: 'nonexistent_scope',
          ),
        );

        expect(disposed, false);
        expect(scopeManager.activeScopeCount, 0);
      });

      test('observer handles unregistered route gracefully', () {
        expect(scopeObserver.getScopeConfig('unregistered'), isNull);
        expect(scopeObserver.hasRegisteredScope('unregistered'), false);
      });
    });

    group('Scope reset', () {
      test('resets all scopes and clears state', () async {
        await scopeManager.createRouteScope(
          const ScopedRouteConfig(routePath: '/test1', scopeName: 'scope1'),
        );
        await scopeManager.createRouteScope(
          const ScopedRouteConfig(routePath: '/test2', scopeName: 'scope2'),
        );
        await scopeManager.createRouteScope(
          const ScopedRouteConfig(routePath: '/test3', scopeName: 'scope3'),
        );

        expect(scopeManager.activeScopeCount, 3);

        await scopeObserver.reset();

        expect(scopeManager.activeScopeCount, 0);
        expect(scopeObserver.registeredScopeCount, 0);
      });
    });
  });
}
