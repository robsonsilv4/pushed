import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:pushed/pushed.dart';

void main() {
  group('ScopeObserver', () {
    late ScopeObserver observer;
    late RouteScopeManager scopeManager;
    late GetIt getIt;

    setUp(() {
      getIt = GetIt.instance;
      unawaited(getIt.reset());
      scopeManager = RouteScopeManager();
      observer = ScopeObserver(scopeManager: scopeManager);
    });

    tearDown(() async {
      await scopeManager.resetAllScopes();
      await getIt.reset();
    });

    group('initialization', () {
      test('creates observer with custom scope manager', () {
        expect(observer.scopeManager, isNotNull);
        expect(identical(observer.scopeManager, scopeManager), isTrue);
      });

      test('initializes with empty registered scopes', () {
        expect(observer.registeredScopeCount, equals(0));
        expect(observer.registeredRoutes, isEmpty);
      });

      test('initializes with empty active scopes', () {
        expect(observer.activeScopeCount, equals(0));
        expect(observer.activeRoutes, isEmpty);
      });

      test('logging is disabled by default', () {
        expect(observer.enableLogging, isFalse);
      });

      test('can be created with logging enabled', () {
        final loggingObserver = ScopeObserver(enableLogging: true);
        expect(loggingObserver.enableLogging, isTrue);
      });
    });

    group('registerRouteScope', () {
      test('registers a route scope configuration', () {
        const config = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
        );

        observer.registerRouteScope('dashboard', config);

        expect(observer.hasRegisteredScope('dashboard'), isTrue);
        expect(observer.registeredScopeCount, equals(1));
        expect(observer.registeredRoutes, contains('dashboard'));
      });

      test('stores and retrieves the exact configuration', () {
        const config = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
          isFinal: true,
        );

        observer.registerRouteScope('dashboard', config);

        final retrieved = observer.getScopeConfig('dashboard');
        expect(retrieved, isNotNull);
        expect(retrieved!.routePath, equals('/dashboard'));
        expect(retrieved.scopeName, equals('dashboard'));
        expect(retrieved.isFinal, isTrue);
      });

      test('prevents duplicate route registration', () {
        const config = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
        );

        observer.registerRouteScope('dashboard', config);

        expect(
          () => observer.registerRouteScope('dashboard', config),
          throwsArgumentError,
        );
        // Verify count didn't increase
        expect(observer.registeredScopeCount, equals(1));
      });

      test('supports registering multiple different routes', () {
        const config1 = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
        );
        const config2 = ScopedRouteConfig(
          routePath: '/settings',
          scopeName: 'settings',
        );
        const config3 = ScopedRouteConfig(
          routePath: '/profile',
          scopeName: 'profile',
        );

        observer
          ..registerRouteScope('dashboard', config1)
          ..registerRouteScope('settings', config2)
          ..registerRouteScope('profile', config3);

        expect(observer.registeredScopeCount, equals(3));
        expect(
          observer.registeredRoutes,
          containsAll(['dashboard', 'settings', 'profile']),
        );
      });

      test('stores initializer and disposer callbacks', () {
        var initCalled = false;

        final config = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
          scopeInitializer: (getIt) {
            initCalled = true;
          },
          scopeDisposer: (getIt) async {
            // Async cleanup
          },
        );

        observer.registerRouteScope('dashboard', config);
        final retrieved = observer.getScopeConfig('dashboard');

        // Verify callbacks are stored
        expect(retrieved?.scopeInitializer, isNotNull);
        expect(retrieved?.scopeDisposer, isNotNull);

        // Verify they work when called
        retrieved?.scopeInitializer?.call(getIt);
        expect(initCalled, isTrue);
      });
    });

    group('unregisterRouteScope', () {
      test('successfully unregisters a registered route', () {
        const config = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
        );

        observer.registerRouteScope('dashboard', config);
        expect(observer.registeredScopeCount, equals(1));

        final removed = observer.unregisterRouteScope('dashboard');

        expect(removed, isTrue);
        expect(observer.registeredScopeCount, equals(0));
        expect(observer.hasRegisteredScope('dashboard'), isFalse);
      });

      test('returns false when unregistering non-existent route', () {
        final removed = observer.unregisterRouteScope('nonexistent');
        expect(removed, isFalse);
      });

      test('does not affect other registered routes', () {
        const config1 = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
        );
        const config2 = ScopedRouteConfig(
          routePath: '/settings',
          scopeName: 'settings',
        );

        observer
          ..registerRouteScope('dashboard', config1)
          ..registerRouteScope('settings', config2)
          ..unregisterRouteScope('dashboard');

        expect(observer.registeredScopeCount, equals(1));
        expect(observer.hasRegisteredScope('settings'), isTrue);
        expect(observer.hasRegisteredScope('dashboard'), isFalse);
      });
    });

    group('getScopeConfig', () {
      test('returns configuration for registered route', () {
        const config = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
        );

        observer.registerRouteScope('dashboard', config);

        final retrieved = observer.getScopeConfig('dashboard');
        expect(retrieved, isNotNull);
        expect(retrieved?.routePath, equals('/dashboard'));
      });

      test('returns null for unregistered route', () {
        final retrieved = observer.getScopeConfig('nonexistent');
        expect(retrieved, isNull);
      });
    });

    group('hasRegisteredScope', () {
      test('returns true for registered route', () {
        const config = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
        );

        observer.registerRouteScope('dashboard', config);

        expect(observer.hasRegisteredScope('dashboard'), isTrue);
      });

      test('returns false for unregistered route', () {
        expect(observer.hasRegisteredScope('nonexistent'), isFalse);
      });
    });

    group('hasActiveScope', () {
      test('returns false when scope is not active', () {
        const config = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
        );

        observer.registerRouteScope('dashboard', config);

        expect(observer.hasActiveScope('dashboard'), isFalse);
      });

      test('returns false for unregistered route', () {
        expect(observer.hasActiveScope('nonexistent'), isFalse);
      });
    });

    group('reset', () {
      test('clears all registered routes', () async {
        const config1 = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
        );
        const config2 = ScopedRouteConfig(
          routePath: '/settings',
          scopeName: 'settings',
        );

        observer
          ..registerRouteScope('dashboard', config1)
          ..registerRouteScope('settings', config2);

        expect(observer.registeredScopeCount, equals(2));

        await observer.reset();

        expect(observer.registeredScopeCount, equals(0));
        expect(observer.registeredRoutes, isEmpty);
      });

      test('clears all active scopes via scope manager', () async {
        final config = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
          scopeInitializer: (getIt) {
            getIt.registerSingleton<String>('test_value');
          },
        );

        observer.registerRouteScope('dashboard', config);
        await scopeManager.createRouteScope(config);

        expect(scopeManager.activeScopeCount, equals(1));

        await observer.reset();

        expect(scopeManager.activeScopeCount, equals(0));
        expect(observer.activeScopeCount, equals(0));
      });
    });

    group('query methods', () {
      test('registeredRoutes returns immutable list of route names', () {
        const config = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
        );

        observer.registerRouteScope('dashboard', config);

        final routes = observer.registeredRoutes;
        expect(routes, contains('dashboard'));

        // Verify it's a defensive copy (unmodifiable)
        expect(
          () => routes.add('new_route'),
          throwsUnsupportedError,
        );
      });

      test('activeRoutes returns immutable list of active scope names', () {
        final routes = observer.activeRoutes;
        expect(routes, isEmpty);

        // Verify it's a defensive copy (unmodifiable)
        expect(
          () => routes.add('new_route'),
          throwsUnsupportedError,
        );
      });

      test('handles multiple registered and active scopes', () {
        const config1 = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
        );
        const config2 = ScopedRouteConfig(
          routePath: '/settings',
          scopeName: 'settings',
        );

        observer
          ..registerRouteScope('dashboard', config1)
          ..registerRouteScope('settings', config2);

        expect(observer.registeredScopeCount, equals(2));
        expect(observer.registeredRoutes.length, equals(2));
      });
    });

    group('error handling', () {
      test('gracefully handles reset when no scopes exist', () async {
        // Should not throw
        await observer.reset();
        expect(observer.registeredScopeCount, equals(0));
      });

      test('throws ArgumentError when registering duplicate', () {
        const config = ScopedRouteConfig(
          routePath: '/dashboard',
          scopeName: 'dashboard',
        );

        observer.registerRouteScope('dashboard', config);

        expect(
          () => observer.registerRouteScope('dashboard', config),
          throwsArgumentError,
        );
      });
    });
  });
}
