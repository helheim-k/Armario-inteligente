import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/outfit_controller.dart';
import '../controllers/wardrobe_controller.dart';
import '../models/calendar_entry_model.dart';
import '../models/garment_model.dart';
import '../models/outfit_model.dart';


class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarController _calendarController = CalendarController();
  final OutfitController _outfitController = OutfitController();
  final WardrobeController _wardrobeController = WardrobeController();

  late final Stream<List<OutfitModel>> _outfitsStream;
  late final Stream<List<GarmentModel>> _garmentsStream;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime _visibleMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _outfitsStream = _outfitController.watchOutfits();
    _garmentsStream = _wardrobeController.watchGarments();
  }

  Future<void> _openAssignSheet(
    DateTime day,
    List<OutfitModel> outfits,
    List<GarmentModel> garments,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AssignDaySheet(
        day: day,
        outfits: outfits,
        garments: garments,
        onSaveOutfit: (outfitId) => _calendarController.assignOutfitToDate(
          date: day,
          outfitId: outfitId,
        ),
        onSaveGarments: (garmentIds) => _calendarController.assignGarmentsToDate(
          date: day,
          garmentIds: garmentIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Calendario de outfits"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<List<GarmentModel>>(
        stream: _garmentsStream,
        builder: (context, garmentsSnapshot) {
          final allGarments = garmentsSnapshot.data ?? [];
          final garmentsById = {for (final g in allGarments) g.id: g};

          return StreamBuilder<List<OutfitModel>>(
            stream: _outfitsStream,
            builder: (context, outfitsSnapshot) {
              final allOutfits = outfitsSnapshot.data ?? [];
              final outfitsById = {for (final o in allOutfits) o.id: o};

              return StreamBuilder<List<CalendarEntryModel>>(
                stream: _calendarController.watchEntriesForMonth(_visibleMonth),
                builder: (context, entriesSnapshot) {
                  final entries = entriesSnapshot.data ?? [];
                  final entriesByDay = <DateTime, CalendarEntryModel>{};
                  for (final e in entries) {
                    entriesByDay[DateTime(e.date.year, e.date.month, e.date.day)] = e;
                  }

                  final selectedEntry = _selectedDay == null
                      ? null
                      : entriesByDay[DateTime(
                          _selectedDay!.year, _selectedDay!.month, _selectedDay!.day)];

                  return Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime(2020, 1, 1),
                        lastDay: DateTime(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            _selectedDay != null && isSameDay(_selectedDay, day),
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDay = selected;
                            _focusedDay = focused;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                            _visibleMonth = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.pinkDark,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppColors.pinkDark.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: AppColors.pinkDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        eventLoader: (day) {
                          final key = DateTime(day.year, day.month, day.day);
                          return entriesByDay.containsKey(key) ? [entriesByDay[key]] : [];
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _selectedDay == null
                            ? const SizedBox()
                            : _SelectedDayPanel(
                                day: _selectedDay!,
                                entry: selectedEntry,
                                outfit: selectedEntry?.outfitId != null
                                    ? outfitsById[selectedEntry!.outfitId]
                                    : null,
                                garments: selectedEntry == null
                                    ? []
                                    : (selectedEntry.outfitId != null
                                        ? (outfitsById[selectedEntry.outfitId]
                                                ?.garmentIds ??
                                            [])
                                            .map((id) => garmentsById[id])
                                            .whereType<GarmentModel>()
                                            .toList()
                                        : selectedEntry.garmentIds
                                            .map((id) => garmentsById[id])
                                            .whereType<GarmentModel>()
                                            .toList()),
                                onAssign: () => _openAssignSheet(
                                  _selectedDay!,
                                  allOutfits,
                                  allGarments,
                                ),
                                onRemove: selectedEntry == null
                                    ? null
                                    : () => _calendarController.removeEntry(_selectedDay!),
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SelectedDayPanel extends StatelessWidget {
  final DateTime day;
  final CalendarEntryModel? entry;
  final OutfitModel? outfit;
  final List<GarmentModel> garments;
  final VoidCallback onAssign;
  final VoidCallback? onRemove;

  const _SelectedDayPanel({
    required this.day,
    required this.entry,
    required this.outfit,
    required this.garments,
    required this.onAssign,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${day.day}/${day.month}/${day.year}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton.icon(
                onPressed: onAssign,
                icon: const Icon(Icons.checkroom),
                label: Text(entry == null ? "Asignar outfit" : "Cambiar"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (entry == null)
            const Expanded(
              child: Center(child: Text("Todavía no has asignado nada para este día.")),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (outfit != null)
                    Text(outfit!.name ?? 'Outfit sin nombre',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: garments.isEmpty
                        ? const Text("Prendas no disponibles")
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: garments.length,
                            itemBuilder: (context, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                base64Decode(garments[i].imageBase64),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                  ),
                  if (onRemove != null)
                    TextButton(
                      onPressed: onRemove,
                      child: const Text("Quitar de este día", style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AssignDaySheet extends StatefulWidget {
  final DateTime day;
  final List<OutfitModel> outfits;
  final List<GarmentModel> garments;
  final Future<void> Function(String outfitId) onSaveOutfit;
  final Future<void> Function(List<String> garmentIds) onSaveGarments;

  const _AssignDaySheet({
    required this.day,
    required this.outfits,
    required this.garments,
    required this.onSaveOutfit,
    required this.onSaveGarments,
  });

  @override
  State<_AssignDaySheet> createState() => _AssignDaySheetState();
}

class _AssignDaySheetState extends State<_AssignDaySheet> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String> _selectedGarmentIds = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveOutfit(String outfitId) async {
    setState(() => _saving = true);
    await widget.onSaveOutfit(outfitId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveGarments() async {
    if (_selectedGarmentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona al menos una prenda.")),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.onSaveGarments(_selectedGarmentIds.toList());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            "${widget.day.day}/${widget.day.month}/${widget.day.year}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.pinkDark,
            tabs: const [
              Tab(text: "Outfit guardado"),
              Tab(text: "Prendas sueltas"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                widget.outfits.isEmpty
                    ? const Center(child: Text("No tienes outfits guardados."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: widget.outfits.length,
                        itemBuilder: (context, index) {
                          final outfit = widget.outfits[index];
                          return ListTile(
                            title: Text(outfit.name ?? 'Outfit sin nombre'),
                            subtitle: outfit.occasion != null ? Text(outfit.occasion!) : null,
                            trailing: _saving
                                ? const SizedBox(
                                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.chevron_right),
                            onTap: _saving ? null : () => _saveOutfit(outfit.id!),
                          );
                        },
                      ),
                widget.garments.isEmpty
                    ? const Center(child: Text("No tienes prendas registradas."))
                    : Column(
                        children: [
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: widget.garments.length,
                              itemBuilder: (context, index) {
                                final garment = widget.garments[index];
                                final selected = _selectedGarmentIds.contains(garment.id);
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    if (selected) {
                                      _selectedGarmentIds.remove(garment.id);
                                    } else {
                                      _selectedGarmentIds.add(garment.id!);
                                    }
                                  }),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: selected ? AppColors.pinkDark : Colors.transparent,
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        base64Decode(garment.imageBase64),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _saveGarments,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.pinkDark,
                                  foregroundColor: Colors.white,
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text("Guardar"),
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}