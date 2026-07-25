import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_register_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _ReviewItem {
  final String userName;
  final double rating;
  final String timeAgo;
  final String eventInfo;
  final String comment;

  _ReviewItem({
    required this.userName,
    required this.rating,
    required this.timeAgo,
    required this.eventInfo,
    required this.comment,
  });
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  EventModel? _event;
  bool _isLoading = true;
  late List<_ReviewItem> _reviews;

  // Biletino & Bubilet İnteraktif Bilet Seçimi Durumu
  final GlobalKey _ticketSectionKey = GlobalKey();
  int _selectedTicketCategoryIndex = 0;
  int _ticketQuantity = 1;

  @override
  void initState() {
    super.initState();
    _reviews = [];
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    final event = await ApiService.getEventDetail(widget.eventId);
    final rawReviews = await ApiService.getReviews(widget.eventId);

    List<_ReviewItem> loadedReviews = rawReviews.map((r) {
      final rawName = (r['user_name'] != null && r['user_name'].toString().trim().isNotEmpty)
          ? r['user_name']
          : (r['username'] ?? 'Kullanıcı');
      final rating = r['rating'] != null ? (r['rating'] as num).toDouble() : 5.0;
      final createdAtStr = r['created_at'] != null
          ? DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.parse(r['created_at']))
          : 'Yakın zamanda';

      return _ReviewItem(
        userName: rawName,
        rating: rating,
        timeAgo: createdAtStr,
        eventInfo: '${event?.locationName ?? 'Mekan'} mekanında izledi',
        comment: r['comment'] ?? '',
      );
    }).toList();

    if (loadedReviews.isEmpty) {
      loadedReviews = [
        _ReviewItem(
          userName: 'Özlem K.',
          rating: 5.0,
          timeAgo: '3 gün önce',
          eventInfo: 'Harbiye Açıkhava Tiyatrosu mekanında izledi',
          comment: 'Çok güzeldi çok seviyoruz',
        ),
        _ReviewItem(
          userName: 'Serenay S.',
          rating: 5.0,
          timeAgo: '15 gün önce',
          eventInfo: 'CerModern mekanında izledi',
          comment: 'Unutulmaz anlardan biriydi 😘',
        ),
      ];
    }

    setState(() {
      _event = event;
      _reviews = loadedReviews;
      _isLoading = false;
    });
  }

  void _showAuthRequiredDialog(BuildContext context, String actionText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Giriş Yapmanız Gerekiyor',
          style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '$actionText için lütfen giriş yapın veya ücretsiz kayıt olun.',
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginRegisterScreen()),
              );
            },
            child: const Text('Giriş Yap / Kayıt Ol', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // google haritalar mekanı acma fonksiyonu
  Future<void> _openGoogleMaps(String locationName, String city) async {
    final query = Uri.encodeComponent('$locationName, $city');
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(googleMapsUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harita açılamadı: $e')),
        );
      }
    }
  }



  // --- satın alma onay modalı ("emin misiniz?" kontrolü) ---
  void _showPurchaseConfirmationDialog(BuildContext context, AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      _showAuthRequiredDialog(context, 'Bilet satın almak');
      return;
    }

    if (authProvider.currentUser?.isAdmin == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin kullanıcılar bilet satın alamaz. Yönetim paneline erişiminiz vardır.')),
      );
      return;
    }

    if (_event == null) return;

    if (_event!.isJoined) {
      // İptal onay diyaloğu
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Katılımı İptal Et', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Text('Biletinizi/katılımınızı iptal etmek istediğinizden emin misiniz?', style: GoogleFonts.inter(fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _handleJoinOrLeave(authProvider);
              },
              child: const Text('Katılımı İptal Et'),
            ),
          ],
        ),
      );
      return;
    }

    final categoryNames = ['Saha İçi / Ayakta Genel Giriş', 'Tribün 1. Kategori (Numaralı)', 'VIP Sahne Önü Protokol'];
    final categoryName = categoryNames[_selectedTicketCategoryIndex];
    final unitMultiplier = [1.0, 1.5, 2.5][_selectedTicketCategoryIndex];
    final totalPrice = _event!.price * unitMultiplier * _ticketQuantity;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.confirmation_number_rounded, color: Color(0xFFE65100), size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Bilet Satın Alımı',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bilet alma işlemini onaylıyor musunuz?',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Özet Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _event!.title,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text('${_event!.locationName}, ${_event!.city}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kategori:', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                      Text(categoryName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Adet:', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                      Text('$_ticketQuantity Adet (Maks. 3 Bilet)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Toplam Tutar:', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                      Text(
                        _event!.isFree ? 'ÜCRETSİZ' : '₺${totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Vazgeç', style: GoogleFonts.outfit(color: Colors.black45, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleJoinOrLeave(authProvider);
            },
            child: Text('Satın Almayı Onayla', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // --- sosyal paylaşma ve davet modalı ---
  void _showShareModal(BuildContext context, EventModel event) {
    final dateFormat = DateFormat('dd MMMM yyyy - HH:mm', 'tr_TR');
    final dateStr = dateFormat.format(event.startDatetime);
    final shareMessage = '''
🎉 Bak ne buldum! Seni de bu etkinliğe bekliyorum:

📌 ${event.title}
📍 ${event.locationName}, ${event.city}
📅 $dateStr
🎫 Fiyat: ${event.isFree ? 'Ücretsiz' : '₺${event.price}'}

Detayları incelemek ve katılmak için uygulamaya göz at!
''';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Etkinliği Paylaş',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black45),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF25D366),
                child: Icon(Icons.share, color: Colors.white, size: 20),
              ),
              title: Text('WhatsApp & Sosyal Medyada Paylaş', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              subtitle: const Text('Arkadaşlarına etkinlik daveti gönder'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                Share.share(shareMessage, subject: event.title);
              },
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF0066FF).withValues(alpha: 0.1),
                child: const Icon(Icons.copy, color: Color(0xFF0066FF), size: 20),
              ),
              title: Text('Metni / Daveti Kopyala', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              subtitle: const Text('Panoya kopyala ve istediğin yere yapıştır'),
              onTap: () {
                Navigator.pop(ctx);
                Share.share(shareMessage);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Etkinlik davet metni kopyalandı!'), backgroundColor: Colors.green),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleJoinOrLeave(AuthProvider authProvider) async {
    if (!authProvider.isAuthenticated) {
      _showAuthRequiredDialog(context, 'Etkinliğe katılmak');
      return;
    }

    if (authProvider.currentUser?.isAdmin == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin kullanıcılar etkinliklere katılamaz. Yönetim yetkisine sahipsiniz.')),
      );
      return;
    }

    if (_event == null) return;
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    if (_event!.isJoined) {
      // provider uzerinden katilim iptal etme tetiklemesi
      final res = await eventProvider.leaveEvent(_event!);
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() => _event!.isJoined = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Katılımınız iptal edildi.'), backgroundColor: Colors.orange),
        );
        _loadDetail();
      }
    } else {
      // provider uzerinden bilet alma ve katilma tetiklemesi
      final res = await eventProvider.joinEvent(_event!, quantity: _ticketQuantity);
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_ticketQuantity adet biletiniz başarıyla tanımlandı!'), backgroundColor: Colors.green),
        );
        _loadDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Hata oluştu.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(
          child: Text('Etkinlik bulunamadı.', style: TextStyle(color: Colors.black87)),
        ),
      );
    }

    final dateFormat = DateFormat('dd MMMM yyyy, EEEE - HH:mm', 'tr_TR');
    final formattedStart = dateFormat.format(_event!.startDatetime);
    final formattedEnd = DateFormat('dd MMMM yyyy, EEEE - HH:mm', 'tr_TR').format(_event!.endDatetime);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF0066FF),
          elevation: 3,
          automaticallyImplyLeading: false,
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Geri Dön & Logo
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 12),
                      const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 6),
                      Text(
                        'etkinlik',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // KULLANICI ÜST MENÜ BUTONLARI (Ana Sayfa ile 1:1 Birebir Aynı)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: Text('Keşfet', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text('Takvim', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: Text('Profilim', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          actions: [
            // Paylaş Butonu
            IconButton(
              icon: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 20),
              onPressed: () => _showShareModal(context, _event!),
            ),
            // Favori Butonu
            IconButton(
              icon: Icon(
                _event!.isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _event!.isFavorited ? Colors.redAccent : Colors.white,
                size: 20,
              ),
              onPressed: () async {
                if (!authProvider.isAuthenticated) {
                  _showAuthRequiredDialog(context, 'Favorilere eklemek');
                } else {
                  // provider uzerinden favorilere ekleme veya cıkarma tetiklemesi
                  await eventProvider.toggleFavorite(_event!);
                  setState(() => _event!.isFavorited = !_event!.isFavorited);
                }
              },
            ),
            const SizedBox(width: 6),

            // HESABIM DROPDOWN MENÜSÜ (Ana Sayfa ile 1:1 Birebir Aynı)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: PopupMenuButton<String>(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                offset: const Offset(0, 45),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await authProvider.logout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      authProvider.isAuthenticated ? 'Kullanıcı: ${authProvider.currentUser?.username}' : 'Misafir Kullanıcı',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  if (authProvider.isAuthenticated) ...[
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Text('Çıkış Yap', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        authProvider.isAuthenticated ? authProvider.currentUser!.username : 'Hesabım',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- biletino tarzı üst hero header paneli ---
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 850;

                  final infoColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Onaylı Etkinlik Rozeti (Biletino Yeşil Rozet)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Onaylı Etkinlik',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Etkinlik Başlığı
                      Text(
                        _event!.title,
                        style: GoogleFonts.outfit(
                          fontSize: isWide ? 32 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Kategori & Konum Etiketi
                      Row(
                        children: [
                          if (_event!.category != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                _event!.category!.name,
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text(
                            '${_event!.city}, ${_event!.locationName}',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Fiyat Aralığı (Biletino Tarzı)
                      Text(
                        _event!.isFree ? 'ÜCRETSİZ' : '₺${_event!.price.toStringAsFixed(2)} - ₺${(_event!.price * 2.5).toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // BİLETLERİ GÖR Butonu (Biletino Turuncu Accent)
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                          label: Text(
                            'BİLETLERİ GÖR',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                          ),
                          onPressed: () {
                            if (_ticketSectionKey.currentContext != null) {
                              Scrollable.ensureVisible(
                                _ticketSectionKey.currentContext!,
                                alignment: 0.0,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  );

                  final imageCard = Container(
                    height: isWide ? 280 : 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _event!.image ?? 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1200&q=80',
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: const Color(0xFF0066FF),
                          child: const Icon(Icons.event, size: 60, color: Colors.white),
                        ),
                      ),
                    ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 6, child: infoColumn),
                        const SizedBox(width: 40),
                        Expanded(flex: 5, child: imageCard),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        imageCard,
                        const SizedBox(height: 20),
                        infoColumn,
                      ],
                    );
                  }
                },
              ),
            ),
            const Divider(height: 1),

            // --- biletino çift sütun ana içerik gövdesi ---
            Padding(
              padding: const EdgeInsets.all(28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 850;

                  // SOL SÜTUN: Etkinlik Detayları, Kurallar, Değerlendirmeler
                  final leftContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Etkinlik Detayları',
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _event!.description,
                        style: GoogleFonts.inter(fontSize: 15, color: Colors.black87, height: 1.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kapı Açılışı: 16:00',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 28),

                      // --- kontenjan ve doluluk oranı göstergesi ---
                      Builder(
                        builder: (context) {
                          final capacity = _event!.capacity;
                          final count = _event!.participantCount;
                          final remaining = capacity - count;
                          final percent = (count / capacity).clamp(0.0, 1.0);
                          final isLow = remaining <= 10;

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isLow ? Colors.orange.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isLow ? Colors.orange.shade300 : Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isLow ? Icons.local_fire_department : Icons.pie_chart_outline_rounded,
                                          color: isLow ? Colors.deepOrange : const Color(0xFF0066FF),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Kontenjan ve Doluluk Durumu',
                                          style: GoogleFonts.outfit(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isLow ? Colors.deepOrange : const Color(0xFF0066FF).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isLow ? '🔥 SON $remaining BİLET!' : '%${(percent * 100).toInt()} Dolu',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isLow ? Colors.white : const Color(0xFF0066FF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // İlerleme Çubuğu (Doluluk Barı)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    minHeight: 10,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isLow ? Colors.deepOrange : (percent > 0.8 ? Colors.orange : const Color(0xFF0066FF)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Toplam Kapasite: $capacity Kişilik',
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                                    ),
                                    Text(
                                      'Kalan Bilet: $remaining Adet',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isLow ? Colors.deepOrange : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // --- interaktif bilet türü ve koltuk seçimi ---
                      Container(
                        key: _ticketSectionKey,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF0066FF).withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0066FF).withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.confirmation_number_outlined, color: Color(0xFF0066FF), size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Bilet Türü ve Koltuk Seçimi',
                                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Text(
                                    'Kullanıcı Başına Maks. 3 Bilet',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Bilet Kategorileri Listesi
                            ...[
                              {'title': 'Saha İçi / Ayakta Genel Giriş', 'subtitle': 'Sahne önü ayakta izleme alanı', 'multiplier': 1.0, 'icon': Icons.directions_walk_rounded},
                              {'title': 'Tribün 1. Kategori (Numaralı)', 'subtitle': 'Orta tribün numaralı koltuk düzeni', 'multiplier': 1.5, 'icon': Icons.chair_alt_rounded},
                              {'title': 'VIP Sahne Önü Protokol', 'subtitle': 'Sahneye sıfır bistro masa & ikramlı', 'multiplier': 2.5, 'icon': Icons.workspace_premium_rounded},
                            ].asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              final isSel = _selectedTicketCategoryIndex == idx;
                              final tierPrice = _event!.price * (item['multiplier'] as double);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF0066FF).withValues(alpha: 0.05) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFF0066FF) : Colors.grey.shade200,
                                    width: isSel ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    if (!authProvider.isAuthenticated) {
                                      _showAuthRequiredDialog(context, 'Bilet türü seçmek');
                                    } else {
                                      setState(() => _selectedTicketCategoryIndex = idx);
                                    }
                                  },
                                  leading: Icon(item['icon'] as IconData, color: isSel ? const Color(0xFF0066FF) : Colors.black45),
                                  title: Text(
                                    item['title'] as String,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
                                  ),
                                  subtitle: Text(item['subtitle'] as String, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                                  trailing: Text(
                                    '₺${tierPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0066FF), fontSize: 15),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 14),
                            const Divider(),
                            const SizedBox(height: 14),

                            // Adet Seçici ve Toplam Tutar + Bilet Al Butonu
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Bilet Adedi (Maks 3)', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        IconButton(
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.grey.shade100,
                                            minimumSize: const Size(36, 36),
                                          ),
                                          icon: const Icon(Icons.remove, size: 18),
                                          onPressed: () {
                                            if (!authProvider.isAuthenticated) {
                                              _showAuthRequiredDialog(context, 'Bilet adedi değiştirmek');
                                            } else if (_ticketQuantity > 1) {
                                              setState(() => _ticketQuantity--);
                                            }
                                          },
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            '$_ticketQuantity',
                                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        IconButton(
                                          style: IconButton.styleFrom(
                                            backgroundColor: const Color(0xFF0066FF).withValues(alpha: 0.1),
                                            minimumSize: const Size(36, 36),
                                          ),
                                          icon: const Icon(Icons.add, color: Color(0xFF0066FF), size: 18),
                                          onPressed: () {
                                            if (!authProvider.isAuthenticated) {
                                              _showAuthRequiredDialog(context, 'Bilet adedi değiştirmek');
                                            } else if (_ticketQuantity < 3) {
                                              setState(() => _ticketQuantity++);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Bir kişi en fazla 3 bilet alabilir.'),
                                                  backgroundColor: Colors.orange,
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Toplam Tutar', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₺${(_event!.price * ([1.0, 1.5, 2.5][_selectedTicketCategoryIndex]) * _ticketQuantity).toStringAsFixed(2)}',
                                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Kart İçi Satın Al Butonu
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _event!.isJoined ? Colors.redAccent : const Color(0xFFE65100),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: Icon(_event!.isJoined ? Icons.cancel_outlined : Icons.shopping_bag_outlined, size: 20),
                                label: Text(
                                  _event!.isJoined ? 'Bileti İptal Et' : 'Bilet Al',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                onPressed: () => _showPurchaseConfirmationDialog(context, authProvider),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // --- değerlendirmeler ve yorumlar bölümü ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Değerlendirmeler',
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${_reviews.length + 98})',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.black45,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '4.9',
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (index) => const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0066FF).withValues(alpha: 0.08),
                                foregroundColor: const Color(0xFF0066FF),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              icon: const Icon(Icons.rate_review_outlined, size: 18),
                              label: Text(
                                'Yorum / Değerlendirme Ekle',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: () {
                                if (!authProvider.isAuthenticated) {
                                  _showAuthRequiredDialog(context, 'Değerlendirme yapmak');
                                } else {
                                  _showAddReviewDialog(context, authProvider);
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            const Divider(height: 1),
                            const SizedBox(height: 16),

                            // Yorum Kartları Listesi
                            ..._reviews.map((rev) => _buildReviewCard(rev)),
                          ],
                        ),
                      ),
                    ],
                  );

                  // SAĞ SÜTUN: Biletino Sağ Bilgi Kutusu (Başlangıç/Bitiş Tarihi + Konum)
                  final rightSidebar = Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5), // Biletino Gri Yan Kutu
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Başlangıç Tarihi',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedStart,
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Bitiş Tarihi',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedEnd,
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        Text(
                          'Konum',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_event!.locationName}, ${_event!.city}',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, height: 1.4),
                        ),
                        const SizedBox(height: 12),

                        // google haritalarda ac butonu
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: Text(
                            'Google Haritalar\'da Aç',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () => _openGoogleMaps(_event!.locationName, _event!.city),
                        ),
                      ],
                    ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: leftContent),
                        const SizedBox(width: 32),
                        Expanded(flex: 4, child: rightSidebar),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        leftContent,
                        const SizedBox(height: 28),
                        rightSidebar,
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),

      // Alt Buton (Kaldırıldı)
      bottomNavigationBar: null,
    );
  }

  Widget _buildReviewCard(_ReviewItem rev) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    rev.userName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: List.generate(
                      rev.rating.toInt(),
                      (index) => const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    ),
                  ),
                ],
              ),
              Text(
                rev.timeAgo,
                style: GoogleFonts.inter(color: Colors.black38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rev.eventInfo,
            style: GoogleFonts.inter(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            rev.comment,
            style: GoogleFonts.inter(color: Colors.black87, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context, AuthProvider authProvider) {
    final commentController = TextEditingController();
    double userRating = 5.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Değerlendirme Yap',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Puanınız:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < userRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        userRating = (index + 1).toDouble();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Etkinlik hakkındaki düşüncelerinizi yazın...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            // veritabanina yorum kaydetme butonu
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (commentController.text.trim().isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(ctx);

                  final success = await ApiService.addReview(
                    widget.eventId,
                    userRating.toInt(),
                    commentController.text.trim(),
                  );

                  if (success) {
                    await _loadDetail();
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Değerlendirmeniz veritabanına kaydedildi ve yayınlandı!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Yorum kaydedilemedi. Lütfen tekrar deneyin.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
  }
}
