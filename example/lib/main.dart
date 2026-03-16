import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pushed/pushed.dart';

void main() {
  runApp(const App());
}

// Example service
class ProductService {
  final List<String> products = ['Product A', 'Product B', 'Product C'];

  Future<void> dispose() async {
    // Cleanup if needed
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final ScopeObserver _scopeObserver;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _scopeObserver = ScopeObserver();
    _router = GoRouter(
      observers: [_scopeObserver],
      routes: [
        GoRoute(
          path: '/',
          name: 'products',
          builder: (context, state) => const ProductsPage(),
        )..withScope(
            observer: _scopeObserver,
            scopeInitializer: (getIt) {
              getIt.registerSingleton<ProductService>(ProductService());
            },
            scopeDisposer: (getIt) async {
              await getIt<ProductService>().dispose();
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pushed Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      routerConfig: _router,
    );
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: ListView.builder(
        itemCount: productService.products.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(productService.products[index]),
          );
        },
      ),
    );
  }
}
