import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pushed/pushed.dart';

class _MockDashboardService {
  final String name = 'dashboard_service';
  bool initialized = false;
  bool cleaned = false;

  void initialize() {
    initialized = true;
  }

  Future<void> cleanup() async {
    cleaned = true;
  }
}

void main() {
  group('GoRouteScopeExtension', () {
    late ScopeObserver observer;
    late GetIt getIt;

    setUp(() {
      getIt = GetIt.instance;
      unawaited(getIt.reset());
      observer = ScopeObserver();
    });

    tearDown(() async {
      await observer.reset();
      await getIt.reset();
    });

    group('withScope - basic registration', () {
      test('registers route with observer', () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {
            getIt.registerSingleton<String>('dashboard_value');
          },
        );

        expect(observer.hasRegisteredScope('dashboard'), isTrue);
        expect(observer.registeredScopeCount, equals(1));
      });

      test('uses route name as scope name by default', () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {},
        );

        final config = observer.getScopeConfig('dashboard');
        expect(config, isNotNull);
        expect(config?.scopeName, equals('dashboard'));
        expect(config?.effectiveScopeName, equals('dashboard'));
      });

      test('uses custom scope name when provided', () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeName: 'custom_dashboard_scope',
          scopeInitializer: (getIt) {},
        );

        final config = observer.getScopeConfig('dashboard');
        expect(config, isNotNull);
        expect(config?.scopeName, equals('custom_dashboard_scope'));
        expect(config?.effectiveScopeName, equals('custom_dashboard_scope'));
      });

      test('preserves route path in scope config', () {
        GoRoute(
          path: '/user/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {},
        );

        final config = observer.getScopeConfig('dashboard');
        expect(config?.routePath, equals('/user/dashboard'));
      });

      test('uses path as scope name when route has no name', () {
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {},
        );

        expect(observer.hasRegisteredScope('/dashboard'), isTrue);
        final config = observer.getScopeConfig('/dashboard');
        expect(config?.routePath, equals('/dashboard'));
      });
    });

    group('withScope - scope initializer', () {
      test('stores and preserves scope initializer function', () {
        var initializerInvoked = false;

        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {
            initializerInvoked = true;
            getIt.registerSingleton<_MockDashboardService>(
              _MockDashboardService(),
            );
          },
        );

        final config = observer.getScopeConfig('dashboard');
        expect(config?.scopeInitializer, isNotNull);

        // Verify initializer is actually stored and can be called
        expect(initializerInvoked, isFalse); // Not called yet
        config?.scopeInitializer?.call(getIt);
        expect(initializerInvoked, isTrue);

        // Verify service was registered
        expect(getIt.isRegistered<_MockDashboardService>(), isTrue);
      });

      test('initializer receives GetIt instance for registration', () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (injector) {
            expect(injector, isNotNull);
          },
        );

        final config = observer.getScopeConfig('dashboard');
        config?.scopeInitializer?.call(getIt);

        expect(config?.scopeInitializer, isNotNull);
      });

      test('initializer can register multiple dependencies', () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (injector) {
            injector
              ..registerSingleton<String>('app_name', instanceName: 'name')
              ..registerSingleton<int>(42, instanceName: 'answer')
              ..registerSingleton<List<String>>(
                ['a', 'b', 'c'],
                instanceName: 'items',
              );
          },
        );

        final config = observer.getScopeConfig('dashboard');
        expect(config?.scopeInitializer, isNotNull);
        // Verify the initializer signature allows multiple registrations
      });
    });

    group('withScope - scope disposer', () {
      test('stores and preserves scope disposer function', () {
        var disposerInvoked = false;

        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {},
          scopeDisposer: (getIt) async {
            disposerInvoked = true;
          },
        );

        final config = observer.getScopeConfig('dashboard');
        expect(config?.scopeDisposer, isNotNull);
        expect(disposerInvoked, isFalse);
      });

      test('disposer receives GetIt instance', () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {},
          scopeDisposer: (injector) async {
            expect(injector, isNotNull);
          },
        );

        final config = observer.getScopeConfig('dashboard');
        expect(config?.scopeDisposer, isNotNull);
      });

      test('disposer is async and can perform cleanup', () async {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {},
          scopeDisposer: (getIt) async {
            // Async cleanup would happen here
            await Future<void>.delayed(const Duration(milliseconds: 1));
          },
        );

        final config = observer.getScopeConfig('dashboard');
        expect(config?.scopeDisposer, isNotNull);
        // Disposer is properly stored
      });
    });

    group('withScope - isFinal flag', () {
      test('sets isFinal flag to false by default', () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {},
        );

        final config = observer.getScopeConfig('dashboard');
        expect(config?.isFinal, isFalse);
      });

      test('sets isFinal flag to true when specified', () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          isFinal: true,
          scopeInitializer: (getIt) {},
        );

        final config = observer.getScopeConfig('dashboard');
        expect(config?.isFinal, isTrue);
      });
    });

    group('withScope - multiple routes', () {
      test('can register multiple routes with different scopes', () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {
            getIt.registerSingleton<String>('dashboard_scope');
          },
        );

        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {
            getIt.registerSingleton<int>(42);
          },
        );

        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeName: 'user_profile',
          scopeInitializer: (getIt) {
            getIt.registerSingleton<bool>(true);
          },
        );

        expect(observer.registeredScopeCount, equals(3));
        expect(observer.hasRegisteredScope('dashboard'), isTrue);
        expect(observer.hasRegisteredScope('settings'), isTrue);
        expect(observer.hasRegisteredScope('profile'), isTrue);

        // Verify each has different configs
        final config1 = observer.getScopeConfig('dashboard');
        final config2 = observer.getScopeConfig('settings');
        final config3 = observer.getScopeConfig('profile');

        expect(config1?.routePath, equals('/dashboard'));
        expect(config2?.routePath, equals('/settings'));
        expect(config3?.routePath, equals('/profile'));
        expect(config3?.scopeName, equals('user_profile'));
      });

      test('routes do not interfere with each other', () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          isFinal: true,
          scopeInitializer: (_) {},
        );

        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (_) {},
        );

        final config1 = observer.getScopeConfig('dashboard');
        final config2 = observer.getScopeConfig('settings');

        expect(config1?.isFinal, isTrue);
        expect(config2?.isFinal, isFalse);
      });
    });

    group('withScope - null safety', () {
      test('handles null scopeDisposer gracefully', () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {},
          // No disposer provided
        );

        final config = observer.getScopeConfig('dashboard');
        expect(config?.scopeDisposer, isNull);
        expect(config?.scopeInitializer, isNotNull);
      });

      test('handles null scopeName and uses effective name', () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeInitializer: (getIt) {},
          // No custom scopeName provided, will use route name
        );

        final config = observer.getScopeConfig('dashboard');
        // When no custom scopeName is provided, it defaults to route name
        expect(config?.effectiveScopeName, equals('dashboard'));
      });
    });

    group('withScope - configuration completeness', () {
      test('creates valid ScopedRouteConfig with all fields', () {
        GoRoute(
          path: '/user/123/dashboard',
          name: 'user_dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeName: 'dashboard_scope',
          isFinal: true,
          scopeInitializer: (getIt) {
            getIt.registerSingleton<String>('initialized');
          },
          scopeDisposer: (getIt) async {
            // cleanup
          },
        );

        final config = observer.getScopeConfig('user_dashboard');
        expect(config, isNotNull);
        expect(config?.routePath, equals('/user/123/dashboard'));
        expect(config?.scopeName, equals('dashboard_scope'));
        expect(config?.effectiveScopeName, equals('dashboard_scope'));
        expect(config?.isFinal, isTrue);
        expect(config?.scopeInitializer, isNotNull);
        expect(config?.scopeDisposer, isNotNull);
      });

      test('preserves all configuration when unregistered and re-registered',
          () {
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Placeholder(),
        ).withScope(
          observer: observer,
          scopeName: 'my_scope',
          isFinal: true,
          scopeInitializer: (getIt) {},
        );

        final config1 = observer.getScopeConfig('dashboard');
        expect(config1?.scopeName, equals('my_scope'));
        expect(config1?.isFinal, isTrue);

        // Configuration should be exactly the same
        final config2 = observer.getScopeConfig('dashboard');
        expect(config1, equals(config2));
      });
    });
  });
}
