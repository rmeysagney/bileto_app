import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../event_detail/event_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ep = Provider.of<EventProvider>(context, listen: false);
      ep.fetchMyEvents();
      ep.fetchEvents();
    });
  }

  List<EventModel> _getEventsForDay(DateTime day, List<EventModel> myEvents) {
    return myEvents.where((e) {
      return isSameDay(e.startDatetime, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    // Takvimde hem kullanıcının katıldığı hem de genel etkinlikleri göster
    final allEvents = eventProvider.myEvents.isNotEmpty ? eventProvider.myEvents : eventProvider.events;
    final selectedDayEvents = _getEventsForDay(_selectedDay ?? _focusedDay, allEvents);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Taze Light Arka Plan
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAŞLIK ALANI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Etkinlik Takvimi',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tarihlere göre planlanmış tüm etkinlikleri inceleyin.',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.today, size: 16, color: Color(0xFF0066FF)),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMMM yyyy', 'tr_TR').format(_focusedDay),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0066FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TEMİZ BİLETİX STİLİ LIGHT TAKVİM KARTI
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TableCalendar<EventModel>(
                  locale: 'tr_TR',
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: (day) => _getEventsForDay(day, allEvents),

                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },

                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },

                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },

                  // LIGHT STİL YAPILANDIRMASI
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: GoogleFonts.outfit(
                      color: const Color(0xFF0066FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    titleTextStyle: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.black87),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.black87),
                  ),

                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.inter(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12),
                    weekendStyle: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),

                  calendarStyle: CalendarStyle(
                    defaultTextStyle: GoogleFonts.inter(color: Colors.black87),
                    weekendTextStyle: GoogleFonts.inter(color: Colors.black87),
                    outsideTextStyle: GoogleFonts.inter(color: Colors.black26),

                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: GoogleFonts.inter(color: const Color(0xFF0066FF), fontWeight: FontWeight.bold),

                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF0066FF),
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),

                    markerDecoration: const BoxDecoration(
                      color: Color(0xFF0066FF),
                      shape: BoxShape.circle,
                    ),
                    markerSize: 6,
                    markersMaxCount: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SEÇİLİ TARİHTEKİ ETKİNLİKLER BAŞLIĞI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDay != null
                      ? '${DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDay!)} Etkinlikleri'
                      : 'Günün Etkinlikleri',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    '${selectedDayEvents.length} Etkinlik',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ETKİNLİK LİSTESİ
            if (selectedDayEvents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.event_available, size: 48, color: Colors.black26),
                    const SizedBox(height: 12),
                    Text(
                      'Bu tarihte planlanmış bir etkinlik bulunmuyor.',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedDayEvents.length,
                itemBuilder: (context, index) {
                  final event = selectedDayEvents[index];
                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: event.image != null
                            ? Image.network(
                                event.image!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  width: 60,
                                  height: 60,
                                  color: const Color(0xFF0066FF),
                                  child: const Icon(Icons.event, color: Colors.white),
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: const Color(0xFF0066FF),
                                child: const Icon(Icons.event, color: Colors.white),
                              ),
                      ),
                      title: Text(
                        event.title,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '📍 ${event.locationName}, ${event.city}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                          Text(
                            '🕒 ${DateFormat('HH:mm').format(event.startDatetime)} - ${DateFormat('HH:mm').format(event.endDatetime)}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: event.isFree ? Colors.green.shade50 : const Color(0xFF0066FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          event.isFree ? 'ÜCRETSİZ' : '₺${event.price}',
                          style: TextStyle(
                            color: event.isFree ? Colors.green.shade700 : const Color(0xFF0066FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(eventId: event.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
