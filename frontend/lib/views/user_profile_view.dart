import 'package:flutter/material.dart';

/// Salt okunur kullanıcı profil görüntüleme ekranı
/// Keşfet kısmından bir kullanıcıya tıklandığında açılır
class UserProfileView extends StatelessWidget {
  final Map<String, dynamic> userMap;

  const UserProfileView({super.key, required this.userMap});

  // Tema Renkleri (ProfileScreen ile uyumlu)
  static const Color _primaryStart = Color(0xFF667eea);
  static const Color _primaryEnd = Color(0xFF764ba2);

  @override
  Widget build(BuildContext context) {
    // userMap'ten verileri çıkar
    final String? avatarUrl = userMap['avatar_url'] as String?;
    final String firstName = userMap['first_name'] as String? ?? '';
    final String lastName = userMap['last_name'] as String? ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final int? age = userMap['age'] as int?;
    final String? city = userMap['city'] as String?;
    final String? bio = userMap['bio'] as String?;
    final List<dynamic>? interestsList = userMap['interests'] as List<dynamic>?;
    final List<String> interests =
        interestsList?.map((e) => e.toString()).toList() ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Gradient Header with Profile Photo
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: _primaryStart,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryStart, _primaryEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Büyük Profil Fotoğrafı
                      _buildProfilePhoto(avatarUrl),
                      const SizedBox(height: 16),
                      // İsim
                      Text(
                        fullName.isNotEmpty ? fullName : 'Kullanıcı',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Yaş ve Şehir
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (age != null) ...[
                            const Icon(
                              Icons.cake_outlined,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$age yaş',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                          if (age != null && city != null)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '•',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          if (city != null && city.isNotEmpty) ...[
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              city,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // İçerik
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hakkımda Bölümü
                  if (bio != null && bio.isNotEmpty)
                    _buildSectionCard(
                      title: 'Hakkımda',
                      icon: Icons.info_outline,
                      child: Text(
                        bio,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                    ),

                  if (bio != null && bio.isNotEmpty) const SizedBox(height: 20),

                  // İlgi Alanları Bölümü
                  if (interests.isNotEmpty)
                    _buildSectionCard(
                      title: 'İlgi Alanları',
                      icon: Icons.favorite_outline,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: interests
                            .map((interest) => _buildInterestChip(interest))
                            .toList(),
                      ),
                    ),

                  // Boş profil durumu
                  if ((bio == null || bio.isEmpty) && interests.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bu kullanıcı henüz profil bilgilerini\ndoldurmamış',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Büyük Profil Fotoğrafı Widget'ı
  Widget _buildProfilePhoto(String? avatarUrl) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, size: 70, color: Colors.grey),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _primaryStart,
                      ),
                    ),
                  );
                },
              )
            : const Icon(Icons.person, size: 70, color: Colors.grey),
      ),
    );
  }

  /// Section Card Widget'ı (Bio, Interests için)
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryStart, _primaryEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// İlgi Alanı Chip Widget'ı
  Widget _buildInterestChip(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryStart.withOpacity(0.1),
            _primaryEnd.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _primaryStart.withOpacity(0.3), width: 1),
      ),
      child: Text(
        interest,
        style: const TextStyle(
          color: Color(0xFF667eea),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
