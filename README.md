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
  pushed: ^0.1.0
  go_router: ^14.0.0
  get_it: ^7.6.0
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
  builder: (context, state) => ProductsPage(),
).withScope(
  observer: scopeObserver,
  scopeInitializer: (getIt) {
    getIt.registerSingleton<ProductService>(ProductService());
  },
  scopeDisposer: (getIt) async {
    // cleanup if needed
  },
)
```

### 4. Access dependencies in your pages

```dart
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productService = GetIt.instance<ProductService>();
    return // your UI
  }
}
```

## 📚 Complete Example

See the [example app](example/) for a complete working example with:
- Multiple routes with scoped dependencies
- Service lifecycle management

Run the example:
```bash
cd example
flutter run
```

## 💡 Scope Lifecycle

```
Navigate to /products
  ↓
ScopeObserver detects route change
  ↓
ScopeInitializer called
  ↓
Services registered in GetIt
  ↓
Page can access services via GetIt.instance<Service>()
  ↓
Navigate away from /products
  ↓
ScopeDisposer called
  ↓
Services removed from GetIt
  ↓
Memory freed
```

## 🎯 Best Practices

### 1. Always initialize services in `scopeInitializer`

```dart
.withScope(
  observer: observer,
  scopeInitializer: (getIt) {
    getIt.registerSingleton<UserService>(UserService());
    getIt.registerSingleton<AuthService>(AuthService());
  },
)
```

### 2. Clean up resources in `scopeDisposer`

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

### 3. Use hierarchical scopes for related routes

```dart
GoRoute(
  path: '/products',
  builder: (context, state) => ProductsPage(),
).withScope(
  observer: observer,
  scopeInitializer: (getIt) {
    getIt.registerSingleton<ProductService>(ProductService());
  },
  routes: [
    GoRoute(
      path: ':id',
      builder: (context, state) => ProductDetailPage(),
    ).withScope(
      observer: observer,
      scopeInitializer: (getIt) {
        // ProductService is still available from parent scope
        getIt.registerSingleton<ReviewService>(ReviewService());
      },
    ),
  ],
)
```

## 📈 Performance

- Minimal overhead - scopes are created/disposed only when needed
- No global state pollution - each scope is isolated
- Efficient memory management - automatic cleanup prevents leaks

## 🐛 Troubleshooting

### Service not found error

**Problem**: `GetIt.get<MyService>() not found`

**Cause**: The scope hasn't been initialized yet

**Solution**: 
- Ensure you've navigated to the route with the scoped service
- Verify the service is registered in `scopeInitializer`
- Check that `ScopeObserver` is added to `GoRouter`

### Memory leaks

**Problem**: Services are not being cleaned up

**Solution**:
- Implement `scopeDisposer` callbacks
- Ensure disposer methods actually clean up resources
- Call `dispose()` on services that need cleanup

### Scope conflicts

**Problem**: Services from different scopes interfering

**Solution**:
- Use unique service names for different scopes
- Avoid registering globally when you need scoped services
- Check `GetIt.isRegistered<Service>()` before registering

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

## 🤝 Contributing

Contributions are welcome! Please see the example app and tests for patterns.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Packages

- [`go_router`](https://pub.dev/packages/go_router) - Declarative routing for Flutter
- [`get_it`](https://pub.dev/packages/get_it) - Service locator for Dart
- [`provider`](https://pub.dev/packages/provider) - State management

## 📧 Support

For issues, questions, or suggestions, please open an issue on GitHub.
