# pushed

Scoped dependencies for `go_router` routes using `get_it`.

Enables automatic dependency injection and lifecycle management for route-specific dependencies in Flutter applications using `go_router`.

## 🎯 Features

- **Route-Scoped Dependencies** - Register dependencies specific to individual routes
- **Automatic Lifecycle** - Services are created when routes are entered and disposed when exited
- **Hierarchical Scopes** - Support for nested routes with scope inheritance
- **Type-Safe** - Full Dart type safety for dependency access
- **Easy Integration** - Simple extensions that work seamlessly with `go_router` and `get_it`
- **Async Support** - Both initialization and disposal support async operations
- **Zero Boilerplate** - Minimal code to integrate into your app

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  pushed: ^0.2.1
  go_router: ^17.0.0
  get_it: ^9.0.0
```

Then run:
```bash
flutter pub get
```

## 🚀 Quick Start

### 1. Create a `ScopeObserver`

```dart
final scopeObserver = ScopeObserver();
```

### 2. Add observer to `GoRouter`

```dart
GoRouter(
  observers: [scopeObserver],
  routes: [
    // your routes here
  ],
)
```

### 3. Register scoped dependencies

```dart
GoRoute(
  path: '/products',
  name: 'products',
  builder: (context, state) => const ProductsPage(),
).withScope(
  observer: scopeObserver,
  scopeInitializer: (getIt) {
    getIt.registerSingleton<ProductService>(ProductService());
  },
  scopeDisposer: (getIt) async {
    final service = getIt<ProductService>();
    await service.dispose();
  },
)
```

### 4. Access dependencies in your pages

```dart
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = GetIt.instance<ProductService>();
    return Scaffold(
      body: // use productService
    );
  }
}
```

## 📚 Complete Example

See the [example app](example/) for a complete working example demonstrating:
- Creating a `ScopeObserver`
- Registering scoped dependencies
- Accessing dependencies with `GetIt`
- Automatic cleanup when routes are popped

Run the example:
```bash
cd example
flutter run
```

## 💡 Scope Lifecycle

```
Navigate to route with scope
  ↓
ScopeObserver detects route push
  ↓
scopeInitializer called
  ↓
Services registered in GetIt scope
  ↓
Page can access via GetIt.instance<Service>()
  ↓
Navigate away / route popped
  ↓
scopeDisposer called
  ↓
Services removed from GetIt
  ↓
Memory freed
```

## 🎯 Best Practices

### 1. Always use `scopeDisposer` for cleanup

```dart
.withScope(
  observer: observer,
  scopeInitializer: (getIt) {
    getIt.registerSingleton<DatabaseService>(DatabaseService());
  },
  scopeDisposer: (getIt) async {
    await getIt<DatabaseService>().close();
  },
)
```

### 2. Register multiple related services

```dart
scopeInitializer: (getIt) {
  getIt.registerSingleton<UserService>(UserService());
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerSingleton<PreferencesService>(PreferencesService());
}
```

### 3. Use hierarchical scopes for nested routes

```dart
GoRoute(
  path: '/products',
  builder: (context, state) => ProductsPage(),
  routes: [
    GoRoute(
      path: ':id',
      builder: (context, state) => ProductDetailPage(),
    ).withScope(
      observer: observer,
      scopeInitializer: (getIt) {
        // Can access parent scope services
        getIt.registerSingleton<ProductDetailService>(
          ProductDetailService(),
        );
      },
    ),
  ],
).withScope(
  observer: observer,
  scopeInitializer: (getIt) {
    getIt.registerSingleton<ProductService>(ProductService());
  },
)
```

## 🧪 Testing

Use `resetAllScopes()` in tests:

```dart
test('my test', () async {
  final router = createRouter();
  
  // Navigate and test
  // ...
  
  // Cleanup
  await router.resetAllScopes();
});
```

## 📈 Performance

- **Minimal overhead** - Scopes created/disposed only when needed
- **No global state pollution** - Each scope is isolated
- **Efficient memory management** - Automatic cleanup prevents leaks
- **Type-safe** - Full Dart type checking at compile time

## 🐛 Troubleshooting

### Service not found error

**Problem**: `GetIt.get<MyService>() not found`

**Solution**: 
- Ensure `ScopeObserver` is added to `GoRouter.observers`
- Verify service is registered in `scopeInitializer`
- Check that you've navigated to the route

### Memory leaks

**Problem**: Services not being cleaned up

**Solution**:
- Implement `scopeDisposer` callbacks
- Ensure services implement proper cleanup
- Use `router.resetAllScopes()` in tests

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Packages

- [`go_router`](https://pub.dev/packages/go_router) - Declarative routing for Flutter
- [`get_it`](https://pub.dev/packages/get_it) - Service locator for Dart
- [`provider`](https://pub.dev/packages/provider) - State management

## 💬 Support

For issues, questions, or suggestions, please [open an issue](https://github.com/robsonsilv4/pushed/issues) on GitHub.

---

Made with ❤️ by [Robson Silva](https://github.com/robsonsilv4) with assistance from AI.
