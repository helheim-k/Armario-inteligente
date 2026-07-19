import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/wardrobe_controller.dart';
import '../controllers/outfit_controller.dart';
import '../models/garment_model.dart';
import '../services/chat_service.dart';
import '../../home/services/weather_service.dart';
import '../widgets/outfit_preview_sheet.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _DisplayMessage {
  final String role;
  final String text;
  final List<String> garmentIds;
  final bool isOutfitRecommendation;

  _DisplayMessage({
    required this.role,
    required this.text,
    this.garmentIds = const [],
    this.isOutfitRecommendation = false,
  });
}

class _ChatScreenState extends State<ChatScreen> {
  final WardrobeController _wardrobeController = WardrobeController();
  final OutfitController _outfitController = OutfitController();
  final ChatService _chatService = ChatService();
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final Stream<List<GarmentModel>> _garmentsStream;
  final List<_DisplayMessage> _messages = [];
  bool _sending = false;
  String _weatherDescription = 'no especificado';

  @override
  void initState() {
    super.initState();
    _garmentsStream = _wardrobeController.watchGarments();
    _messages.add(_DisplayMessage(
      role: 'assistant',
      text: '¡Hola! Soy tu asistente de estilo 👗 Pregúntame por un outfit, pídeme que busque alguna prenda, o platícame qué necesitas hoy.',
    ));
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final weather = await _weatherService.getCurrentWeather();
      _weatherDescription = '${weather.description}, ${weather.temperature.round()}°C';
    } catch (_) {
      // Si falla, seguimos con "no especificado".
    }
  }

  Future<void> _send(List<GarmentModel> garments) async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_DisplayMessage(role: 'user', text: text));
      _sending = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .map((m) => ChatMessage(role: m.role, content: m.text))
          .toList();

      final reply = await _chatService.sendMessage(
        history: history,
        garments: garments,
        weather: _weatherDescription,
      );

      // Extrae la etiqueta [OUTFIT:...] (recomendación) o [SEARCH:...] (búsqueda)
      final outfitMatch = RegExp(r'\[OUTFIT:([^\]]+)\]').firstMatch(reply);
      final searchMatch = RegExp(r'\[SEARCH:([^\]]+)\]').firstMatch(reply);

      List<String> garmentIds = [];
      bool isOutfitRecommendation = false;
      String cleanText = reply;

      if (outfitMatch != null) {
        garmentIds = outfitMatch.group(1)!.split(',').map((s) => s.trim()).toList();
        cleanText = reply.replaceAll(outfitMatch.group(0)!, '').trim();
        isOutfitRecommendation = true;
      } else if (searchMatch != null) {
        garmentIds = searchMatch.group(1)!.split(',').map((s) => s.trim()).toList();
        cleanText = reply.replaceAll(searchMatch.group(0)!, '').trim();
        isOutfitRecommendation = false;
      }

      setState(() {
        _messages.add(_DisplayMessage(
          role: 'assistant',
          text: cleanText,
          garmentIds: garmentIds,
          isOutfitRecommendation: isOutfitRecommendation,
        ));
      });
    } catch (e) {
      debugPrint('ERROR CHAT: $e');
      setState(() {
        _messages.add(_DisplayMessage(
          role: 'assistant',
          text: 'Tuve un problema para responder. Intenta de nuevo en un momento.',
        ));
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showPreview(List<GarmentModel> garments, String? reason) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OutfitPreviewSheet(garments: garments, reason: reason),
    );
  }

  Future<void> _saveAsOutfit(List<String> garmentIds) async {
    try {
      await _outfitController.createOutfit(garmentIds: garmentIds, source: 'ia');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit guardado en tu lista de Outfits.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el outfit.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Asistente de estilo"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<List<GarmentModel>>(
        stream: _garmentsStream,
        builder: (context, snapshot) {
          final garments = snapshot.data ?? [];
          final garmentsById = {for (final g in garments) g.id: g};

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message.role == 'user';
                    final messageGarments = message.garmentIds
                        .map((id) => garmentsById[id])
                        .whereType<GarmentModel>()
                        .toList();

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.pinkDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(color: isUser ? Colors.white : AppColors.textDark),
                            ),
                            if (messageGarments.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 90,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: messageGarments.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, i) => ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64Decode(messageGarments[i].imageBase64),
                                      width: 70,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              if (message.isOutfitRecommendation) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _showPreview(messageGarments, message.text),
                                        child: const Text("Ver vista previa"),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _saveAsOutfit(message.garmentIds),
                                        child: const Text("Guardar"),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_sending)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: InputDecoration(
                          hintText: 'Escribe tu mensaje...',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _send(garments),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sending ? null : () => _send(garments),
                      icon: const Icon(Icons.send),
                      color: AppColors.pinkDark,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}