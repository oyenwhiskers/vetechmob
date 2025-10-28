import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/ai_diagnose_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_shell.dart';

void main() {
  runApp(const VetMobApp());
}

class VetMobApp extends StatelessWidget {
  const VetMobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => AIDiagnoseProvider()),
      ],
      child: MaterialApp(
        title: 'VETech Mobile',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC1E8F7),
            primary: const Color(0xFFC1E8F7),
            secondary: const Color(0xFF1E3A8A),
          ),
          primaryColor: const Color(0xFFC1E8F7),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFC1E8F7),
            foregroundColor: Color(0xFF1E3A8A),
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC1E8F7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC1E8F7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
            ),
          ),
          // Date Picker Theme - Improved contrast
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Colors.white,
            headerBackgroundColor: const Color(0xFF1E3A8A),
            headerForegroundColor: Colors.white,
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              if (states.contains(WidgetState.disabled)) {
                return Colors.grey.shade400;
              }
              return const Color(0xFF1E3A8A); // Dark navy for better contrast
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1E3A8A);
              }
              return Colors.transparent;
            }),
            todayForegroundColor: WidgetStateProperty.all(const Color(0xFF1E3A8A)),
            todayBackgroundColor: WidgetStateProperty.all(
              const Color(0xFFC1E8F7).withOpacity(0.3),
            ),
            todayBorder: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
            yearForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return const Color(0xFF1E3A8A);
            }),
            yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1E3A8A);
              }
              return Colors.transparent;
            }),
            weekdayStyle: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            dayStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            yearStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          // Time Picker Theme - Improved contrast
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            hourMinuteTextColor: const Color(0xFF1E3A8A),
            dayPeriodTextColor: const Color(0xFF1E3A8A),
            dialHandColor: const Color(0xFF1E3A8A),
            dialBackgroundColor: const Color(0xFFC1E8F7).withOpacity(0.2),
            dialTextColor: const Color(0xFF1E3A8A),
            hourMinuteColor: const Color(0xFFC1E8F7).withOpacity(0.3),
            dayPeriodColor: const Color(0xFFC1E8F7).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        routes: {
          '/': (_) => const _Bootstrapper(),
          LoginScreen.routeName: (_) => const LoginScreen(),
          RegisterScreen.routeName: (_) => const RegisterScreen(),
          HomeShell.routeName: (_) => const HomeShell(),
        },
      ),
    );
  }
}

class _Bootstrapper extends StatefulWidget {
  const _Bootstrapper();

  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();
    if (!mounted) return;
    if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(HomeShell.routeName);
    } else {
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
