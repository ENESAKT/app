import 'dart:math';

/// Sahte kullanıcı modeli - UI test ve demo amaçlı
/// Hash-based seed kullanarak tutarlı veri üretir
class FakeUser {
  final String id;
  final String name;
  final String username;
  final String email;
  final String avatarUrl;
  final String bio;
  final int age;
  final String city;
  final List<String> interests;
  final bool isOnline;
  final int mutualFriends;
  final int followers;
  final int following;
  final DateTime createdAt;

  const FakeUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.bio,
    required this.age,
    required this.city,
    required this.interests,
    this.isOnline = false,
    this.mutualFriends = 0,
    this.followers = 0,
    this.following = 0,
    required this.createdAt,
  });

  /// ID'den Map oluştur (ProfileScreen için)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'bio': bio,
      'age': age,
      'city': city,
      'interests': interests,
      'is_online': isOnline,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Sabit veri listeleri
final _firstNames = [
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
  'Esra',
  'Yasemin',
  'Buse',
  'Hakan',
  'Onur',
];

final _lastNames = [
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
  'Güneş',
  'Ak',
  'Eren',
  'Yavuz',
  'Korkmaz',
];

final _cities = [
  'İstanbul',
  'Ankara',
  'İzmir',
  'Bursa',
  'Antalya',
  'Adana',
  'Konya',
  'Gaziantep',
  'Mersin',
  'Kayseri',
  'Eskişehir',
  'Samsun',
  'Trabzon',
  'Denizli',
  'Muğla',
];

final _bios = [
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

final _allInterests = [
  'Müzik',
  'Sinema',
  'Kitap',
  'Spor',
  'Yemek',
  'Seyahat',
  'Fotoğraf',
  'Oyun',
  'Teknoloji',
  'Sanat',
  'Dans',
  'Yoga',
  'Koşu',
  'Yüzme',
  'Futbol',
  'Basketbol',
  'Tenis',
  'Doğa',
  'Kamp',
  'Bisiklet',
];

/// Hash-based random seed ile tutarlı FakeUser üret
/// Aynı ID için her zaman aynı veriler döner
FakeUser generateFakeUserById(String id) {
  // ID'nin hash değerini seed olarak kullan
  final seed = id.hashCode.abs();
  final random = Random(seed);

  final firstName = _firstNames[random.nextInt(_firstNames.length)];
  final lastName = _lastNames[random.nextInt(_lastNames.length)];
  final fullName = '$firstName $lastName';
  final username = '${firstName.toLowerCase()}${seed % 1000}';

  // 3-5 ilgi alanı seç (tutarlı)
  final interestCount = 3 + random.nextInt(3);
  final shuffledInterests = List<String>.from(_allInterests)..shuffle(random);
  final interests = shuffledInterests.take(interestCount).toList();

  // Tutarlı katılım tarihi (son 2 yıl içinde)
  final daysAgo = random.nextInt(730);
  final createdAt = DateTime.now().subtract(Duration(days: daysAgo));

  return FakeUser(
    id: id,
    name: fullName,
    username: username,
    email: '$username@email.com',
    avatarUrl: 'https://i.pravatar.cc/200?u=$seed',
    bio: _bios[random.nextInt(_bios.length)],
    age: 18 + random.nextInt(28), // 18-45 yaş
    city: _cities[random.nextInt(_cities.length)],
    interests: interests,
    isOnline: random.nextBool(),
    mutualFriends: random.nextInt(15),
    followers: 100 + random.nextInt(9900),
    following: 50 + random.nextInt(500),
    createdAt: createdAt,
  );
}

/// 10 adet tutarlı sahte kullanıcı oluşturur
/// Her çağrıda aynı kullanıcılar döner
List<FakeUser> generateFakeUsers() {
  return List.generate(10, (index) {
    final id = 'fake_${index + 1}';
    return generateFakeUserById(id);
  });
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

/// ID'nin fake user olup olmadığını kontrol et
bool isFakeUserId(String id) {
  return id.startsWith('fake_');
}
