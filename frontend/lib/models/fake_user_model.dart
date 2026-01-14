import 'dart:math';

/// Sahte kullanıcı modeli - UI test ve demo amaçlı
class FakeUser {
  final String id;
  final String name;
  final String username;
  final String avatarUrl;
  final String bio;
  final bool isOnline;
  final int mutualFriends;
  final int followers;
  final int following;

  const FakeUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.bio,
    this.isOnline = false,
    this.mutualFriends = 0,
    this.followers = 0,
    this.following = 0,
  });
}

/// 10 adet rastgele sahte kullanıcı oluşturur
/// Gerçek rastgele avatar resimleri kullanır
List<FakeUser> generateFakeUsers() {
  final random = Random();

  // Türkçe isim listesi
  final firstNames = [
    'Ayşe',
    'Fatma',
    'Zeynep',
    'Elif',
    'Merve',
    'Ahmet',
    'Mehmet',
    'Can',
    'Burak',
    'Emre',
    'Selin',
    'Deniz',
    'Ece',
    'Gizem',
    'Beyza',
    'Ali',
    'Murat',
    'Oğuz',
    'Kerem',
    'Baran',
  ];

  final lastNames = [
    'Yılmaz',
    'Kaya',
    'Demir',
    'Çelik',
    'Şahin',
    'Yıldız',
    'Aydın',
    'Özdemir',
    'Arslan',
    'Doğan',
    'Kılıç',
    'Aslan',
    'Koç',
    'Kurt',
    'Öztürk',
  ];

  // Biyografi şablonları
  final bios = [
    '✨ Hayatı seven, mutlu bir birey',
    '📸 Fotoğraf tutkunu | 🎵 Müzik aşığı',
    '🌍 Gezgin | Keşfetmeyi seven',
    '💻 Yazılım geliştirici | Tech lover',
    '🎨 Sanat ve tasarım tutkunuyum',
    '📚 Kitap kurdu | Sürekli öğrenen',
    '🌿 Doğa sever | Minimalist yaşam',
    '🎮 Gamer | E-spor takipçisi',
    '🍳 Gurme | Yemek denemeci',
    '🏃 Fitness tutkunu | Sağlıklı yaşam',
    '🎬 Film ve dizi konuşmaya bayılırım',
    '☕ Kahve bağımlısı | Kafe avcısı',
  ];

  final List<FakeUser> users = [];

  for (int i = 0; i < 10; i++) {
    final firstName = firstNames[random.nextInt(firstNames.length)];
    final lastName = lastNames[random.nextInt(lastNames.length)];
    final fullName = '$firstName $lastName';
    final username = '${firstName.toLowerCase()}${random.nextInt(999)}';

    // Gerçek rastgele avatar resimleri (pravatar.cc veya randomuser.me)
    // Her kullanıcı için benzersiz seed kullanıyoruz
    final avatarSeed = '${fullName.hashCode.abs()}_$i';

    users.add(
      FakeUser(
        id: 'fake_${i + 1}',
        name: fullName,
        username: username,
        // pravatar.cc - gerçek insan yüzleri
        avatarUrl: 'https://i.pravatar.cc/200?u=$avatarSeed',
        bio: bios[random.nextInt(bios.length)],
        isOnline: random.nextBool(),
        mutualFriends: random.nextInt(15),
        followers: 100 + random.nextInt(9900),
        following: 50 + random.nextInt(500),
      ),
    );
  }

  return users;
}

/// Sahte hikaye verileri için
class FakeStory {
  final String userId;
  final String username;
  final String avatarUrl;
  final bool hasUnseenStory;

  const FakeStory({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    this.hasUnseenStory = true,
  });
}

/// Sahte hikaye kullanıcıları oluşturur
List<FakeStory> generateFakeStories() {
  final users = generateFakeUsers();

  return users
      .take(8)
      .map(
        (user) => FakeStory(
          userId: user.id,
          username: user.username,
          avatarUrl: user.avatarUrl,
          hasUnseenStory: user.isOnline,
        ),
      )
      .toList();
}
