import 'package:get_it/get_it.dart';
import 'package:pushed/pushed.dart';
import 'package:test/test.dart';

void main() {
  group('ScopedRouteConfig', () {
    test('creates instance with required parameters', () {
      const config = ScopedRouteConfig(routePath: '/test');

      expect(config.routePath, equals('/test'));
      expect(config.scopeName, isNull);
      expect(config.scopeInitializer, isNull);
      expect(config.scopeDisposer, isNull);
      expect(config.isFinal, isFalse);
    });

    test('creates instance with all parameters', () {
      void initializer(GetIt getIt) {}
      Future<void> disposer(GetIt getIt) async {}

      final config = ScopedRouteConfig(
        routePath: '/test',
        scopeName: 'custom',
        scopeInitializer: initializer,
        scopeDisposer: disposer,
        isFinal: true,
      );

      expect(config.routePath, equals('/test'));
      expect(config.scopeName, equals('custom'));
      expect(config.scopeInitializer, equals(initializer));
      expect(config.scopeDisposer, equals(disposer));
      expect(config.isFinal, isTrue);
    });

    test('effectiveScopeName returns routePath when scopeName is null', () {
      const config = ScopedRouteConfig(routePath: '/test');

      expect(config.effectiveScopeName, equals('/test'));
    });

    test('effectiveScopeName returns scopeName when provided', () {
      const config = ScopedRouteConfig(
        routePath: '/test',
        scopeName: 'custom',
      );

      expect(config.effectiveScopeName, equals('custom'));
    });

    test('toString returns formatted string', () {
      const config = ScopedRouteConfig(
        routePath: '/test',
        scopeName: 'custom',
        isFinal: true,
      );

      final str = config.toString();

      expect(str, contains('ScopedRouteConfig'));
      expect(str, contains('/test'));
      expect(str, contains('custom'));
      expect(str, contains('true'));
    });

    test('equality based on all fields', () {
      const config1 = ScopedRouteConfig(routePath: '/test');
      const config2 = ScopedRouteConfig(routePath: '/test');

      expect(config1, equals(config2));
    });

    test('inequality when routePath differs', () {
      const config1 = ScopedRouteConfig(routePath: '/test1');
      const config2 = ScopedRouteConfig(routePath: '/test2');

      expect(config1, isNot(equals(config2)));
    });

    test('inequality when isFinal differs', () {
      const config1 = ScopedRouteConfig(
        routePath: '/test',
        isFinal: true,
      );
      const config2 = ScopedRouteConfig(
        routePath: '/test',
      );

      expect(config1, isNot(equals(config2)));
    });

    test('hashCode same for equal configs', () {
      const config1 = ScopedRouteConfig(routePath: '/test');
      const config2 = ScopedRouteConfig(routePath: '/test');

      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('hashCode different for different configs', () {
      const config1 = ScopedRouteConfig(routePath: '/test1');
      const config2 = ScopedRouteConfig(routePath: '/test2');

      expect(config1.hashCode, isNot(equals(config2.hashCode)));
    });

    test('can be used as map key', () {
      const config1 = ScopedRouteConfig(routePath: '/test');
      const config2 = ScopedRouteConfig(routePath: '/test');

      final map = {config1: 'value1'};
      expect(map[config2], equals('value1'));
    });
  });
}
