import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/supabase/supabase_service.dart';

import 'features/dashboard/dashboard_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/sales/sales_screen.dart';
import 'features/customers/customers_screen.dart';
import 'features/more/more_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabaseInit = ref.watch(supabaseInitializerProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      home: supabaseInit.when(
        data: (_) => const MainScreen(),
        loading: () => const SupabaseInitScreen(),
        error: (error, stack) => SupabaseErrorScreen(error: error),
      ),
    );
  }
}

class SupabaseInitScreen extends StatelessWidget {
  const SupabaseInitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Conectando con Supabase...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class SupabaseErrorScreen extends StatelessWidget {
  final Object error;

  const SupabaseErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Error de conexión',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No se pudo conectar con Supabase: $error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Reiniciar la aplicación
                  main();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    InventoryScreen(),
    SalesScreen(),
    CustomersScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ============================================================
      // NAVEGACIÓN INFERIOR
      // ============================================================
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.35),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: NavigationBar(
            height: 72,

            elevation: 0,

            backgroundColor: Colors.transparent,

            surfaceTintColor: Colors.transparent,

            shadowColor: Colors.transparent,

            selectedIndex: _currentIndex,

            labelBehavior:
                NavigationDestinationLabelBehavior.alwaysShow,

            animationDuration:
                const Duration(milliseconds: 250),

            onDestinationSelected: (index) {
              if (_currentIndex == index) return;

              setState(() {
                _currentIndex = index;
              });
            },

            destinations: const [
              // ====================================================
              // INICIO
              // ====================================================
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  size: 24,
                ),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  size: 25,
                ),
                label: 'Inicio',
              ),

              // ====================================================
              // STOCK
              // ====================================================
              NavigationDestination(
                icon: Icon(
                  Icons.inventory_2_outlined,
                  size: 24,
                ),
                selectedIcon: Icon(
                  Icons.inventory_2_rounded,
                  size: 25,
                ),
                label: 'Stock',
              ),

              // ====================================================
              // VENTAS
              // ====================================================
              NavigationDestination(
                icon: Icon(
                  Icons.point_of_sale_outlined,
                  size: 24,
                ),
                selectedIcon: Icon(
                  Icons.point_of_sale_rounded,
                  size: 25,
                ),
                label: 'Ventas',
              ),

              // ====================================================
              // CLIENTES
              // ====================================================
              NavigationDestination(
                icon: Icon(
                  Icons.people_outline_rounded,
                  size: 24,
                ),
                selectedIcon: Icon(
                  Icons.people_rounded,
                  size: 25,
                ),
                label: 'Clientes',
              ),

              // ====================================================
              // MÁS
              // ====================================================
              NavigationDestination(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: 25,
                ),
                selectedIcon: Icon(
                  Icons.more_horiz_rounded,
                  size: 26,
                ),
                label: 'Más',
              ),
            ],
          ),
        ),
      ),
    );
  }
}