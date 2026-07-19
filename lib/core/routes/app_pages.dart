import 'package:flutter/material.dart';
 
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import 'app_routes.dart';
import '../../features/wardrobe/screens/garment_list_screen.dart';
import '../../features/home/screens/favorites_screen.dart';
import '../../features/outfit/screens/outfit_list_screen.dart';
import '../../features/wardrobe/screens/calendar_screen.dart';
import '../../features/wardrobe/screens/chat_screen.dart';

class AppPages {
  static Map<String, WidgetBuilder> routes = {
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.login: (_) => const LoginScreen(),
    AppRoutes.register: (_) => const RegisterScreen(),
    AppRoutes.home: (_) => const HomeScreen(),
    AppRoutes.wardrobe: (_) => const GarmentListScreen(),
    AppRoutes.outfits: (_) => const OutfitListScreen(),
    AppRoutes.calendar: (_) => const CalendarScreen(),
    AppRoutes.favorites: (_) => const FavoritesScreen(),
    AppRoutes.recommendations: (_) => const ChatScreen(),
  };
}