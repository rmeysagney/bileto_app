import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../event_detail/event_detail_screen.dart';
import '../auth/login_register_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedCategoryFilter = 0; // 0: Etkinlik Biletlerim, 1: Spor Biletlerim
  int _selectedStatusFilter = 0; // 0: Aktif Etkinlikler, 1: Geçmiş Etkinlikler

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        final eventProvider = Provider.of<EventProvider>(context, listen: false);
        // provider uzerinden kullanicinin biletlerini cekme tetiklemesi
        eventProvider.fetchMyEvents();
        // provider uzerinden kullanicinin favorilerini cekme tetiklemesi
        eventProvider.fetchMyFavorites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final user = authProvider.currentUser;

    if (!authProvider.isAuthenticated || user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  child: const Icon(Icons.person_outline, size: 50, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Misafir Kullanıcı',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Biletlerinizi görüntülemek ve yönetmek için giriş yapın.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 260,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginRegisterScreen(initialIsRegister: false)),
                      );
                    },
                    child: Text(
                      'Giriş Yap / Kayıt Ol',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Filtrelenmiş Biletler Listesi
    final now = DateTime.now();
    List<EventModel> filteredEvents = eventProvider.myEvents;

    if (_selectedStatusFilter == 0) {
      // Aktif Etkinlikler (Bitiş tarihi henüz geçmemiş olanlar)
      filteredEvents = eventProvider.myEvents.where((e) => e.endDatetime.isAfter(now.subtract(const Duration(days: 1)))).toList();
    } else {
      // Geçmiş Etkinlikler
      filteredEvents = eventProvider.myEvents.where((e) => e.endDatetime.isBefore(now.subtract(const Duration(days: 1)))).toList();
    }

    if (_selectedCategoryFilter == 1) {
      // Spor Biletlerim (Kategori ismi Spor olanlar)
      filteredEvents = filteredEvents.where((e) => e.category?.name.toLowerCase().contains('spor') ?? false).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil Üst Kartı (Kullanıcı Bilgileri & Çıkış)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF2E7D32),
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(user.email, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () async => await authProvider.logout(),
                    icon: const Icon(Icons.logout, size: 14),
                    label: const Text('Çıkış', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // üst tab pilleri (etkinlik biletlerim ve favorilerim)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // etkinlik biletlerim sekme butonu
                  _buildCategoryPill(
                    index: 0,
                    icon: Icons.confirmation_number_outlined,
                    title: 'Etkinlik Biletlerim',
                    count: eventProvider.myEvents.length,
                  ),
                  const SizedBox(width: 12),
                  // favorilerim sekme butonu
                  _buildCategoryPill(
                    index: 1,
                    icon: Icons.favorite_border_rounded,
                    title: 'Favorilerim',
                    count: eventProvider.myFavorites.length,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // BİLET DAHSHBOARD PANELDİR (Biletino 1:1 Aynısı)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 420),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel Başlığı ve Aktif/Geçmiş Etkinlikler Anahtarı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategoryFilter == 0 ? 'Etkinlik Biletlerim' : 'Favori Etkinliklerim',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      if (_selectedCategoryFilter == 0)
                        // Aktif Etkinlikler / Geçmiş Etkinlikler Butonları
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              _buildStatusPill(index: 0, title: 'Aktif Etkinlikler'),
                              _buildStatusPill(index: 1, title: 'Geçmiş Etkinlikler'),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${eventProvider.myFavorites.length} Favori',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // BİLETLER VEYA FAVORİLER LİSTESİ
                  if (_selectedCategoryFilter == 0) ...[
                    if (filteredEvents.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Henüz bilet bulunamadı',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Etkinliklere göz atıp bilet satın alabilirsiniz.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return _buildTicketCard(event, eventProvider);
                        },
                      ),
                  ] else ...[
                    // FAVORİ ETKİNLİKLER LİSTESİ
                    if (eventProvider.myFavorites.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.favorite_border_rounded, size: 60, color: Colors.redAccent),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz favori etkinlik eklemediniz',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'İlgilendiğiniz etkinliklerdeki kalp butonuna basarak favorilerinize ekleyebilirsiniz.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: eventProvider.myFavorites.length,
                        itemBuilder: (context, index) {
                          final event = eventProvider.myFavorites[index];
                          return _buildFavoriteCard(event, eventProvider);
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kategori Pill Butonu (Yeşil / Kırmızı Çerçeveli)
  Widget _buildCategoryPill({required int index, required IconData icon, required String title, int count = 0}) {
    final isSelected = _selectedCategoryFilter == index;
    final color = index == 1 ? Colors.redAccent : const Color(0xFF2E7D32);
    final bgColor = index == 1 ? Colors.red.shade50 : Colors.green.shade50;

    return InkWell(
      // kategori pill tiklama butonu
      onTap: () => setState(() => _selectedCategoryFilter = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Durum Pill Butonu (Aktif / Geçmiş Etkinlikler)
  Widget _buildStatusPill({required int index, required String title}) {
    final isSelected = _selectedStatusFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = index),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: const Color(0xFF2E7D32), width: 1.5) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF2E7D32) : Colors.black54,
          ),
        ),
      ),
    );
  }

  // Bilet Kartı Tasarımı (Dijital Bilet)
  Widget _buildTicketCard(EventModel event, EventProvider eventProvider) {
    final dateStr = DateFormat('dd MMMM yyyy - HH:mm', 'tr_TR').format(event.startDatetime);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2E7D32), size: 32),
        ),
        title: Text(
          event.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.black45),
                const SizedBox(width: 4),
                Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Colors.black45),
                const SizedBox(width: 4),
                Text('${event.locationName}, ${event.city}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black38),
        // bilet detayına gitme butonu
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
          ).then((_) => eventProvider.fetchMyEvents());
        },
      ),
    );
  }

  // favori etkinlik kartı tasarımı
  Widget _buildFavoriteCard(EventModel event, EventProvider eventProvider) {
    final dateStr = DateFormat('dd MMMM yyyy - HH:mm', 'tr_TR').format(event.startDatetime);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            height: 56,
            child: (event.image != null && event.image!.isNotEmpty)
                ? Image.network(event.image!, fit: BoxFit.cover)
                : Container(color: Colors.red.shade50, child: const Icon(Icons.favorite_rounded, color: Colors.redAccent)),
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
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.black45),
                const SizedBox(width: 4),
                Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Colors.black45),
                const SizedBox(width: 4),
                Text('${event.locationName}, ${event.city}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // favorilerden cikar butonu
            IconButton(
              icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 22),
              onPressed: () async {
                await eventProvider.toggleFavorite(event);
              },
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black38),
          ],
        ),
        // favori etkinlik detay incele ve bilet al butonu
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
          ).then((_) => eventProvider.fetchMyFavorites());
        },
      ),
    );
  }
}
