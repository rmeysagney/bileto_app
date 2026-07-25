import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';

class CreateEventScreen extends StatefulWidget {
  final EventModel? eventToEdit;

  const CreateEventScreen({super.key, this.eventToEdit});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _locationController;
  late TextEditingController _cityController;
  late TextEditingController _capacityController;
  late TextEditingController _priceController;

  int? _selectedCategoryId;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late bool _isFree;

  @override
  void initState() {
    super.initState();
    final event = widget.eventToEdit;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    String rawImg = event?.image ?? '';
    if (rawImg.contains('https://')) {
      rawImg = rawImg.substring(rawImg.indexOf('https://'));
    }
    _imageUrlController = TextEditingController(text: rawImg);
    _locationController = TextEditingController(text: event?.locationName ?? '');
    _cityController = TextEditingController(text: event?.city ?? '');
    _capacityController = TextEditingController(text: event?.capacity.toString() ?? '50');
    _priceController = TextEditingController(text: event?.price.toString() ?? '0');

    _selectedCategoryId = event?.category?.id;
    _startDate = event?.startDatetime ?? DateTime.now().add(const Duration(days: 1));
    _startTime = event != null
        ? TimeOfDay(hour: event.startDatetime.hour, minute: event.startDatetime.minute)
        : const TimeOfDay(hour: 18, minute: 0);
    _endDate = event?.endDatetime ?? DateTime.now().add(const Duration(days: 1));
    _endTime = event != null
        ? TimeOfDay(hour: event.endDatetime.hour, minute: event.endDatetime.minute)
        : const TimeOfDay(hour: 21, minute: 0);
    _isFree = event?.isFree ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submitEvent() async {
    if (_formKey.currentState!.validate()) {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_imageUrlController.text.isNotEmpty) 'image': _imageUrlController.text.trim(),
        'start_datetime': startDateTime.toIso8601String(),
        'end_datetime': endDateTime.toIso8601String(),
        'location_name': _locationController.text.trim(),
        'city': _cityController.text.trim(),
        'capacity': int.parse(_capacityController.text.trim()),
        'price': _isFree ? '0.00' : _priceController.text.trim(),
        'is_free': _isFree,
      };

      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      bool success = false;

      if (widget.eventToEdit != null) {
        // Düzenleme Modu (PUT/PATCH API Çağrısı)
        final url = Uri.parse('http://127.0.0.1:8000/api/events/${widget.eventToEdit!.id}/');
        final headers = await ApiService.getHeaders();
        final response = await httpPatch(url, headers, eventData);
        success = response;
      } else {
        // provider uzerinden yeni etkinlik olusturma tetiklemesi
        final res = await eventProvider.createEvent(eventData);
        success = res['success'] == true;
      }

      if (!mounted) return;

      if (success) {
        // provider uzerinden etkinlik listesini yeniden cekme tetiklemesi
        await eventProvider.fetchEvents();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.eventToEdit != null ? 'Etkinlik başarıyla güncellendi!' : 'Etkinlik oluşturuldu ve kullanıcılara yayınlandı!'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.eventToEdit == null) {
          _titleController.clear();
          _descriptionController.clear();
          _imageUrlController.clear();
          _locationController.clear();
          _cityController.clear();
          _capacityController.text = '50';
          _priceController.text = '0';
        }
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem gerçekleştirilemedi. Lütfen bilgileri kontrol edin.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  static Future<bool> httpPatch(Uri url, Map<String, String> headers, Map<String, dynamic> body) async {
    try {
      final res = await ApiService.patchEvent(url, headers, body);
      return res;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final isEditing = widget.eventToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Etkinliği Düzenle' : 'Yeni Etkinlik Oluştur',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Etkinlik Bilgilerini Güncelle' : 'Etkinlik Detayları',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 20),

              // Başlık
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.black87),
                decoration: _buildInputDecoration('Etkinlik Başlığı*', Icons.title),
                validator: (v) => v!.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.black87),
                decoration: _buildInputDecoration('Açıklama*', Icons.description),
                validator: (v) => v!.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 16),

              // Kategori Seçimi
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                style: const TextStyle(color: Colors.black87),
                dropdownColor: Colors.white,
                decoration: _buildInputDecoration('Kategori', Icons.category),
                items: eventProvider.categories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 16),

              // Resim URL
              TextFormField(
                controller: _imageUrlController,
                style: const TextStyle(color: Colors.black87),
                decoration: _buildInputDecoration('Resim URL (İsteğe bağlı)', Icons.image),
              ),
              const SizedBox(height: 16),

              // Konum & Şehir
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _locationController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _buildInputDecoration('Mekan / Adres*', Icons.place),
                      validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _cityController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: _buildInputDecoration('Şehir*', Icons.location_city),
                      validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tarih ve Saat Seçiciler
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat('dd.MM.yyyy').format(_startDate)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (time != null) setState(() => _startTime = time);
                      },
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(_startTime.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ücret Mantığı
              SwitchListTile(
                title: const Text('Ücretsiz Etkinlik', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                value: _isFree,
                activeThumbColor: const Color(0xFF0066FF),
                onChanged: (val) => setState(() => _isFree = val),
              ),
              if (!_isFree) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _buildInputDecoration('Bilet Fiyatı (₺)*', Icons.attach_money),
                  validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                ),
              ],
              const SizedBox(height: 16),

              // Kontenjan
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black87),
                decoration: _buildInputDecoration('Kontenjan (Kişi)*', Icons.people),
                validator: (v) => v!.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 28),

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: eventProvider.isLoading ? null : _submitEvent,
                  child: Text(
                    isEditing ? 'Değişiklikleri Kaydet' : 'Etkinliği Yayınla',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black45, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.black45, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
      ),
    );
  }
}
