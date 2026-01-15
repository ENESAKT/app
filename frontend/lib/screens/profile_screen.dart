import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const ProfileScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();

  UserModel? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isNewProfile = false; // Yeni kullanıcı profili oluşturma modu

  // Tema Renkleri
  static const Color _primaryStart = Color(0xFF667eea);
  static const Color _primaryEnd = Color(0xFF764ba2);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final data = await _supabaseService.getUser(widget.userId);
      if (data != null) {
        final user = UserModel.fromJson(data);
        setState(() {
          _user = user;
          _isNewProfile = false;
          // Formu doldur
          _firstNameController.text = user.firstName ?? '';
          _lastNameController.text = user.lastName ?? '';
          _ageController.text = user.age?.toString() ?? '';
          _cityController.text = user.city ?? '';
          _bioController.text = user.bio ?? '';
          _interestsController.text = user.interests?.join(', ') ?? '';
        });
      } else {
        // Veri yoksa yeni profil oluşturma moduna geç
        setState(() {
          _isNewProfile = true;
          _user = null;
        });
        print('ℹ️ Kullanıcı profili bulunamadı, yeni profil oluşturma modu');
      }
    } catch (e) {
      print('❌ Profil yükleme hatası: $e');
      // Hata durumunda da yeni profil modu
      setState(() {
        _isNewProfile = true;
        _user = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (!widget.isCurrentUser) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isSaving = true);

      // Fotoğrafı yükle
      final url = await _supabaseService.uploadProfilePhoto(image.path);

      if (url != null) {
        // DB güncelle
        await _supabaseService.updateProfile(avatarUrl: url);
        await _loadProfile(); // Profili yenile

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil fotoğrafı güncellendi ✅'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Fotoğraf yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!widget.isCurrentUser) return;

    setState(() => _isSaving = true);

    try {
      // İlgi alanlarını parse et
      List<String>? interests;
      if (_interestsController.text.isNotEmpty) {
        interests = _interestsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      final age = int.tryParse(_ageController.text.trim());

      // upsertProfile kullan - yoksa ekle, varsa güncelle
      await _supabaseService.upsertProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: age,
        city: _cityController.text.trim(),
        bio: _bioController.text.trim(),
        interests: interests ?? [],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Verileri tazelemek için
      await _loadProfile();
    } catch (e) {
      print('❌ Kaydetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydedilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sadece kendi profilimiz ise düzenleme modu açık
    // Değilse readonly mod (fakat bu ekran genelde düzenleme için kullanılır)
    // Eğer başkasının profili ise UserProfileView kullanılır.
    // Bu ekranı "Profil Düzenle" veya "Profilim" olarak kurguluyorum.

    // Dinamik başlık: Yeni profil ise "Profil Oluştur", mevcut ise "Profili Düzenle"
    final String appBarTitle = _isNewProfile
        ? 'Profil Oluştur'
        : 'Profili Düzenle';

    return Scaffold(
      backgroundColor: Colors.grey[50], // Hafif gri arka plan
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryStart, _primaryEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 1. Profil Fotoğrafı
          GestureDetector(
            onTap: _pickAndUploadPhoto,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: ClipOval(
                    child: _user?.avatarUrl != null
                        ? Image.network(
                            _user!.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: _primaryEnd,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 2. İsim & Soyisim
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'Ad',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Soyad',
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Yaş & Şehir
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _ageController,
                  label: 'Yaş',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: 'Şehir',
                  icon: Icons.location_on_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 4. Biyografi
          _buildTextField(
            controller: _bioController,
            label: 'Hakkımda',
            icon: Icons.info_outline,
            maxLines: 4,
          ),

          const SizedBox(height: 16),

          // 5. İlgi Alanları
          _buildTextField(
            controller: _interestsController,
            label: 'İlgi Alanları (virgülle ayırın)',
            icon: Icons.favorite_border,
            hint: 'Müzik, Kodlama, Spor...',
          ),

          const SizedBox(height: 40),

          // 6. Kaydet Butonu
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryStart,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                shadowColor: _primaryStart.withOpacity(0.4),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Kaydet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: _primaryStart),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
