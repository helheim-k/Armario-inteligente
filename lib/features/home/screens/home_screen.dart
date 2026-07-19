import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/time_of_day_helper.dart';
import '../../auth/controllers/profile_controller.dart';
import '../../auth/models/user_model.dart';
import '../../wardrobe/controllers/wardrobe_controller.dart';
import '../../wardrobe/models/garment_model.dart';
import '../../wardrobe/services/recommendation_service.dart';
import '../services/weather_service.dart';
import '../widgets/app_drawer.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProfileController _profileController = ProfileController();
  final WeatherService _weatherService = WeatherService();
  final WardrobeController _wardrobeController = WardrobeController();

  late final Stream<UserModel?> _profileStream;
  late final Stream<List<GarmentModel>> _garmentsStream;
  Future<WeatherInfo>? _weatherFuture;

  @override
  void initState() {
    super.initState();
    _profileStream = _profileController.watchProfile();
    _garmentsStream = _wardrobeController.watchGarments();
    _weatherFuture = _weatherService.getCurrentWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(),
              const SizedBox(height: 20),
              StreamBuilder<UserModel?>(
                stream: _profileStream,
                builder: (context, snapshot) {
                  return FutureBuilder<WeatherInfo>(
                    future: _weatherFuture,
                    builder: (context, weatherSnapshot) {
                      return _GreetingHeader(
                        userName: snapshot.data?.name,
                        weather: weatherSnapshot.data,
                        weatherLoading:
                            weatherSnapshot.connectionState == ConnectionState.waiting,
                        weatherError: weatherSnapshot.hasError,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              StreamBuilder<List<GarmentModel>>(
                stream: _garmentsStream,
                builder: (context, garmentsSnapshot) {
                  return FutureBuilder<WeatherInfo>(
                    future: _weatherFuture,
                    builder: (context, weatherSnapshot) {
                      return _RecommendedCard(
                        garments: garmentsSnapshot.data ?? [],
                        weather: weatherSnapshot.data,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              _QuickActionsGrid(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Barra superior ----------
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundIconButton(
          icon: Icons.menu,
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        const Text(
          "🌸 Armario Inteligente 🌸",
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
        ),
        _RoundIconButton(
          icon: Icons.notifications_none,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.textDark, size: 20),
        ),
      ),
    );
  }
}

// ---------- Saludo + clima real ----------
class _GreetingHeader extends StatelessWidget {
  final String? userName;
  final WeatherInfo? weather;
  final bool weatherLoading;
  final bool weatherError;

  const _GreetingHeader({
    required this.userName,
    required this.weather,
    required this.weatherLoading,
    required this.weatherError,
  });

  @override
  Widget build(BuildContext context) {
    final greeting = TimeOfDayHelper.greetingPrefix();
    final displayName = (userName == null || userName!.isEmpty) ? '' : ', $userName';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      "$greeting$displayName",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.favorite, color: AppColors.pinkDark, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "Descubre tu próximo\noutfit perfecto",
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(TimeOfDayHelper.icon(), color: Colors.orangeAccent, size: 26),
              const SizedBox(height: 4),
              if (weatherLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (weatherError || weather == null)
                const Text("--°C", style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark))
              else
                Text(
                  "${weather!.temperature.round()}°C",
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- Card "Recomendado para hoy" (con IA real) ----------
class _RecommendedCard extends StatefulWidget {
  final List<GarmentModel> garments;
  final WeatherInfo? weather;

  const _RecommendedCard({required this.garments, required this.weather});

  @override
  State<_RecommendedCard> createState() => _RecommendedCardState();
}

class _RecommendedCardState extends State<_RecommendedCard> {
  final RecommendationService _recommendationService = RecommendationService();

  bool _loading = false;
  bool _fetchedOnce = false;
  RecommendedOutfit? _outfit;

  @override
  void initState() {
    super.initState();
    if (widget.garments.isNotEmpty) {
      _fetch();
    }
  }

  @override
  void didUpdateWidget(covariant _RecommendedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_fetchedOnce && widget.garments.isNotEmpty) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    if (widget.garments.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _fetchedOnce = true;
    });

    try {
      final weatherDescription = widget.weather != null
          ? '${widget.weather!.description}, ${widget.weather!.temperature.round()}°C'
          : 'no especificado';

      final results = await _recommendationService.generateOutfits(
        garments: widget.garments,
        weather: weatherDescription,
        occasion: 'casual',
      );

      if (mounted && results.isNotEmpty) {
        setState(() => _outfit = results.first);
      }
    } catch (e) {
      debugPrint('ERROR RECOMENDACIÓN HOME: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final garmentsById = {for (final g in widget.garments) g.id: g};
    final recommendedGarments = _outfit?.garmentIds
            .map((id) => garmentsById[id])
            .whereType<GarmentModel>()
            .toList() ??
        [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("🌟", style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Text(
                "Recomendado para hoy",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.garments.isEmpty)
            const Text(
              "Registra prendas para recibir tu recomendación del día 💕",
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          else if (_loading)
            const SizedBox(
              height: 90,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (recommendedGarments.isEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _GarmentThumb(icon: Icons.checkroom, color: AppColors.pink),
                _GarmentThumb(icon: Icons.dry_cleaning, color: AppColors.cream),
                _GarmentThumb(icon: Icons.straighten, color: AppColors.lavender),
              ],
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: recommendedGarments.take(3).map((g) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    base64Decode(g.imageBase64),
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                );
              }).toList(),
            ),
            if (_outfit?.reason != null && _outfit!.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _outfit!.reason,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// Placeholder de prenda — se usa mientras no hay recomendación de la IA aún
class _GarmentThumb extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _GarmentThumb({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: AppColors.textDark.withOpacity(0.6), size: 36),
    );
  }
}

// ---------- Grid de accesos rápidos ----------
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 2.6,
      children: [
        _QuickActionCard(
          icon: Icons.checkroom_outlined,
          label: "Mis prendas",
          color: AppColors.lavender,
          onTap: () => Navigator.pushNamed(context, AppRoutes.wardrobe),
        ),
        _QuickActionCard(
          icon: Icons.style_outlined,
          label: "Outfits",
          color: AppColors.pink,
          onTap: () => Navigator.pushNamed(context, AppRoutes.outfits),
        ),
        _QuickActionCard(
          icon: Icons.calendar_today_outlined,
          label: "Calendario",
          color: AppColors.cream,
          onTap: () => Navigator.pushNamed(context, AppRoutes.calendar),
        ),
        _QuickActionCard(
          icon: Icons.chat_bubble_outline,
          label: "Asistente IA",
          color: AppColors.mintCard,
          onTap: () => Navigator.pushNamed(context, AppRoutes.recommendations),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.textDark, size: 18),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}