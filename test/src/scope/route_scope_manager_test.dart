import 'package:get_it/get_it.dart';
import 'package:pushed/pushed.dart';
import 'package:test/test.dart';

void main() {
  group('RouteScopeManager', () {
    late RouteScopeManager manager;
    late GetIt getIt;

    setUp(() async {
      // Reset GetIt completely before each test
      getIt = GetIt.instance;
      await getIt.reset();

      // Create new manager instance
      manager = RouteScopeManager();
    });

    tearDown(() async {
      // Clean up after each test
      try {
        await manager.resetAllScopes();
      } catch (e) {
        // Ignore cleanup errors
      }

      try {
        await getIt.reset();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('singleton returns same instance', () {
      final manager1 = RouteScopeManager();
      final manager2 = RouteScopeManager();
      expect(manager1, same(manager2));
    });

    test('createRouteScope registers scope', () async {
      const config = ScopedRouteConfig(routePath: '/test');
      await manager.createRouteScope(config);

      expect(manager.hasScope('/test'), isTrue);
      expect(manager.activeScopes, contains('/test'));
    });

    test('createRouteScope initializes dependencies', () async {
      final config = ScopedRouteConfig(
        routePath: '/test',
        scopeInitializer: (getIt) {
          getIt.registerSingleton<String>('test-value');
        },
      );

      await manager.createRouteScope(config);

      expect(getIt<String>(), equals('test-value'));
    });

    test('createRouteScope throws on duplicate scope name', () async {
      const config = ScopedRouteConfig(routePath: '/test');

      await manager.createRouteScope(config);

      expect(
        () => manager.createRouteScope(config),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('disposeRouteScope removes scope', () async {
      const config = ScopedRouteConfig(routePath: '/test');

      await manager.createRouteScope(config);
      expect(manager.hasScope('/test'), isTrue);

      final result = await manager.disposeRouteScope(config);

      expect(result, isTrue);
      expect(manager.hasScope('/test'), isFalse);
    });

    test('disposeRouteScope returns false for non-existent scope', () async {
      const config = ScopedRouteConfig(routePath: '/test');

      final result = await manager.disposeRouteScope(config);

      expect(result, isFalse);
    });

    test('disposeRouteScope calls disposer function', () async {
      var disposerCalled = false;

      final config = ScopedRouteConfig(
        routePath: '/test',
        scopeInitializer: (getIt) {
          getIt.registerSingleton<String>('test-value');
        },
        scopeDisposer: (getIt) async {
          disposerCalled = true;
        },
      );

      await manager.createRouteScope(config);
      await manager.disposeRouteScope(config);

      expect(disposerCalled, isTrue);
    });

    test('custom scope name is used', () async {
      const config = ScopedRouteConfig(
        routePath: '/test',
        scopeName: 'custom-scope',
      );

      await manager.createRouteScope(config);

      expect(manager.hasScope('custom-scope'), isTrue);
      expect(manager.hasScope('/test'), isFalse);
    });

    test('activeScopes returns unmodifiable list', () async {
      const config = ScopedRouteConfig(routePath: '/test');
      await manager.createRouteScope(config);

      final scopes = manager.activeScopes;

      expect(scopes, isNotEmpty);
      expect(
        () => scopes.add('new-scope'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('currentScope returns last active scope', () async {
      const config1 = ScopedRouteConfig(routePath: '/test1');
      const config2 = ScopedRouteConfig(routePath: '/test2');

      await manager.createRouteScope(config1);
      expect(manager.currentScope, equals('/test1'));

      await manager.createRouteScope(config2);
      expect(manager.currentScope, equals('/test2'));
    });

    test('activeScopeCount returns correct count', () async {
      expect(manager.activeScopeCount, equals(0));

      const config1 = ScopedRouteConfig(routePath: '/test1');
      await manager.createRouteScope(config1);
      expect(manager.activeScopeCount, equals(1));

      const config2 = ScopedRouteConfig(routePath: '/test2');
      await manager.createRouteScope(config2);
      expect(manager.activeScopeCount, equals(2));
    });

    test('resetAllScopes clears all scopes', () async {
      const config1 = ScopedRouteConfig(routePath: '/test1');
      const config2 = ScopedRouteConfig(routePath: '/test2');

      await manager.createRouteScope(config1);
      await manager.createRouteScope(config2);
      expect(manager.activeScopeCount, equals(2));

      await manager.resetAllScopes();

      expect(manager.activeScopeCount, equals(0));
      expect(manager.activeScopes, isEmpty);
    });

    test('isFinal scope is accepted', () async {
      const config = ScopedRouteConfig(
        routePath: '/test',
        isFinal: true,
      );

      await manager.createRouteScope(config);

      expect(manager.hasScope('/test'), isTrue);
    });
  });
}
