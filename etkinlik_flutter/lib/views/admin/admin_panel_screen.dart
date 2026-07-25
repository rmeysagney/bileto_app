import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../organizer/create_event_screen.dart';
import '../event_detail/event_detail_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ep = Provider.of<EventProvider>(context, listen: false);
      ep.fetchEvents();
      ep.fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteEvent(BuildContext context, EventModel event, EventProvider eventProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Etkinliği Sil',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: Text(
          '"${event.title}" etkinliğini sistemden kalıcı olarak silmek istediğinize emin misiniz?',
          style: GoogleFonts.inter(color: Colors.black54, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Sil', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final success = await ApiService.deleteEvent(event.id);
      if (mounted) {
        if (success) {
          eventProvider.fetchEvents();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Etkinlik veritabanından kalıcı olarak silindi.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Silme işlemi başarısız oldu.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // Arama filtrelemesi
    final filteredEvents = eventProvider.events.where((e) {
      final q = _searchQuery.toLowerCase().trim();
      if (q.isEmpty) return true;
      return e.title.toLowerCase().contains(q) ||
          e.city.toLowerCase().contains(q) ||
          e.locationName.toLowerCase().contains(q);
    }).toList();

    // Toplam katılımcı hesabı
    int totalParticipants = 0;
    for (var e in eventProvider.events) {
      totalParticipants += e.participantCount;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () async {
          await eventProvider.fetchEvents();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ADMİN ÜST BANNER KARTI (RESPONSIVE)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 750;
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: isSmall
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.amber.shade300, width: 2),
                                    ),
                                    child: const Icon(Icons.admin_panel_settings_outlined, size: 30, color: Colors.amberAccent),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sistem Yöneticisi Paneli',
                                          style: GoogleFonts.outfit(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Hoş geldin ${user?.fullName ?? 'Admin'}!',
                                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0066FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.add_circle, size: 18),
                                  label: Text(
                                    'Yeni Etkinlik Oluştur',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.amber.shade300, width: 2),
                                ),
                                child: const Icon(Icons.admin_panel_settings_outlined, size: 38, color: Colors.amberAccent),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Sistem Yöneticisi Paneli',
                                          style: GoogleFonts.outfit(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade400,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'SUPERUSER',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Hoş geldin ${user?.fullName ?? 'Admin'}! Tüm etkinlikleri görüntüleyebilir, düzenleyebilir, silebilir ve yeni etkinlik ekleyebilirsin.',
                                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0066FF),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                                  );
                                },
                                icon: const Icon(Icons.add_circle, size: 20),
                                label: Text(
                                  'Yeni Etkinlik Oluştur',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // İSTATİSTİK METRİK KARTLARI (RESPONSIVE WRAP)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 700;
                  if (isNarrow) {
                    return Column(
                      children: [
                        _buildMetricCard(
                          title: 'Toplam Etkinlik',
                          value: eventProvider.events.length.toString(),
                          icon: Icons.event,
                          color: const Color(0xFF0066FF),
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          title: 'Toplam Katılım',
                          value: totalParticipants.toString(),
                          icon: Icons.people_alt_outlined,
                          color: Colors.purple.shade600,
                        ),
                        const SizedBox(height: 12),
                        _buildMetricCard(
                          title: 'Aktif Kategoriler',
                          value: eventProvider.categories.length.toString(),
                          icon: Icons.category_outlined,
                          color: Colors.orange.shade700,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Toplam Etkinlik',
                          value: eventProvider.events.length.toString(),
                          icon: Icons.event,
                          color: const Color(0xFF0066FF),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Toplam Katılım',
                          value: totalParticipants.toString(),
                          icon: Icons.people_alt_outlined,
                          color: Colors.purple.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Aktif Kategoriler',
                          value: eventProvider.categories.length.toString(),
                          icon: Icons.category_outlined,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // ARAMA VE BAŞLIK (RESPONSIVE)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 600;
                  return isSmall
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Etkinlik Yönetimi Listesi',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 13),
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Etkinlik veya şehir ara...',
                                hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.black45),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Etkinlik Yönetimi Listesi',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(
                              width: 300,
                              height: 44,
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontSize: 13),
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: InputDecoration(
                                  hintText: 'Etkinlik veya şehir ara...',
                                  hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                                  prefixIcon: const Icon(Icons.search, size: 18, color: Colors.black45),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 16),

              // ETKİNLİK LİSTESİ / YÖNETİM KARTLARI
              if (eventProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredEvents.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.event_busy, size: 48, color: Colors.black26),
                      const SizedBox(height: 12),
                      Text(
                        'Aramanızla eşleşen yönetilecek etkinlik bulunamadı.',
                        style: GoogleFonts.inter(color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return _buildAdminEventCard(context, event);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MÜKEMMEL RESPONSİVE ADMİN KARTI ---
  Widget _buildAdminEventCard(BuildContext context, EventModel event) {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 750;

            final actionButtons = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0066FF),
                    side: const BorderSide(color: Color(0xFF0066FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(eventId: event.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('İncele', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                    side: BorderSide(color: Colors.orange.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateEventScreen(eventToEdit: event),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Düzenle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _confirmDeleteEvent(context, event, eventProvider),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Sil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: event.image != null
                            ? Image.network(
                                event.image!,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  width: 70,
                                  height: 70,
                                  color: const Color(0xFF0066FF),
                                  child: const Icon(Icons.event, color: Colors.white, size: 28),
                                ),
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                color: const Color(0xFF0066FF),
                                child: const Icon(Icons.event, color: Colors.white, size: 28),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📍 ${event.locationName}, ${event.city}',
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                            Text(
                              '🕒 ${DateFormat('dd.MM.yyyy - HH:mm').format(event.startDatetime)}',
                              style: const TextStyle(color: Colors.black54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: actionButtons),
                ],
              );
            }

            return Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: event.image != null
                      ? Image.network(
                          event.image!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 80,
                            height: 80,
                            color: const Color(0xFF0066FF),
                            child: const Icon(Icons.event, color: Colors.white, size: 30),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: const Color(0xFF0066FF),
                          child: const Icon(Icons.event, color: Colors.white, size: 30),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (event.category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0066FF).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                event.category!.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0066FF),
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: event.isFree ? Colors.green.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.isFree ? 'ÜCRETSİZ' : '₺${event.price}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: event.isFree ? Colors.green.shade700 : const Color(0xFF0066FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📍 ${event.locationName}, ${event.city}  •  🕒 ${DateFormat('dd.MM.yyyy - HH:mm').format(event.startDatetime)}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                actionButtons,
              ],
            );
          },
        ),
      ),
    );
  }
}
