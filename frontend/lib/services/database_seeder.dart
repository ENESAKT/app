import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// Veritabanı Seed Servisi
/// 50 kullanıcı, arkadaşlıklar, istekler, engellenenler ve mesajları veritabanına yazar
class DatabaseSeeder {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseService _supabase = SupabaseService();
  final SupabaseClient _client = Supabase.instance.client;
  final Random _random = Random();

  // 50 Türkçe ve İngilizce isim listesi
  final List<Map<String, String>> _userNames = [
    {'first': 'Ahmet', 'last': 'Yılmaz'},
    {'first': 'Mehmet', 'last': 'Demir'},
    {'first': 'Ayşe', 'last': 'Kaya'},
    {'first': 'Fatma', 'last': 'Çelik'},
    {'first': 'Mustafa', 'last': 'Şahin'},
    {'first': 'Zeynep', 'last': 'Arslan'},
    {'first': 'Ali', 'last': 'Kurt'},
    {'first': 'Emine', 'last': 'Özdemir'},
    {'first': 'Hüseyin', 'last': 'Aydın'},
    {'first': 'Hatice', 'last': 'Öztürk'},
    {'first': 'İbrahim', 'last': 'Yıldız'},
    {'first': 'Elif', 'last': 'Koç'},
    {'first': 'Murat', 'last': 'Polat'},
    {'first': 'Selin', 'last': 'Tunç'},
    {'first': 'Burak', 'last': 'Acar'},
    {'first': 'Deniz', 'last': 'Erdoğan'},
    {'first': 'Can', 'last': 'Yavuz'},
    {'first': 'Merve', 'last': 'Güneş'},
    {'first': 'Emre', 'last': 'Çiçek'},
    {'first': 'Ece', 'last': 'Tekin'},
    {'first': 'John', 'last': 'Smith'},
    {'first': 'Emma', 'last': 'Johnson'},
    {'first': 'Michael', 'last': 'Williams'},
    {'first': 'Sophia', 'last': 'Brown'},
    {'first': 'David', 'last': 'Jones'},
    {'first': 'Olivia', 'last': 'Garcia'},
    {'first': 'James', 'last': 'Miller'},
    {'first': 'Isabella', 'last': 'Davis'},
    {'first': 'Robert', 'last': 'Rodriguez'},
    {'first': 'Mia', 'last': 'Martinez'},
    {'first': 'William', 'last': 'Hernandez'},
    {'first': 'Charlotte', 'last': 'Lopez'},
    {'first': 'Richard', 'last': 'Gonzalez'},
    {'first': 'Amelia', 'last': 'Wilson'},
    {'first': 'Thomas', 'last': 'Anderson'},
    {'first': 'Harper', 'last': 'Thomas'},
    {'first': 'Daniel', 'last': 'Taylor'},
    {'first': 'Evelyn', 'last': 'Moore'},
    {'first': 'Matthew', 'last': 'Jackson'},
    {'first': 'Abigail', 'last': 'Martin'},
    {'first': 'Berat', 'last': 'Yılmaz'},
    {'first': 'Sude', 'last': 'Kara'},
    {'first': 'Kerem', 'last': 'Özkan'},
    {'first': 'Aslı', 'last': 'Bal'},
    {'first': 'Efe', 'last': 'Tok'},
    {'first': 'Defne', 'last': 'Şen'},
    {'first': 'Kaan', 'last': 'Bulut'},
    {'first': 'İrem', 'last': 'Güler'},
    {'first': 'Arda', 'last': 'Akyol'},
    {'first': 'Ela', 'last': 'Taş'},
  ];

  // Örnek bio metinleri (Türkçe ve İngilizce)
  final List<String> _sampleBios = [
    '☕ Kahve tutkunu | 📚 Kitap kurdu',
    '🎸 Müzik aşığı | 🌍 Gezgin ruh',
    'Software Engineer | Tech Enthusiast 💻',
    '🎨 Sanat severim | 🎬 Sinema bağımlısı',
    '🏃 Koşmayı seviyorum | 🧘 Yoga ile huzur buluyorum',
    '🍕 Pizza aşığı | 🍜 Yemek yapmayı seviyorum',
    '📸 Fotoğrafçılık hobim | 🌅 Gün batımı avcısı',
    '🎮 Gamer | 🕹️ Retro oyun koleksiyonum var',
    '✈️ Seyahat etmeyi seviyorum | 🗺️ 25 ülke gezdim',
    '🐶 Hayvan dostu | 🐱 Kedilerimle mutluyum',
    'Marketing Professional | Creative Mind 🎯',
    '🏋️ Fitness enthusiast | 💪 Güçlü kal!',
    '🌱 Doğa sever | 🌳 Ağaç dikmeyi seviyorum',
    '🎭 Tiyatro oyuncusu | 🎪 Sahnede hayat bulurum',
    '📖 Edebiyat öğretmeni | 📝 Yazmayı seviyorum',
    'UX Designer | Making things beautiful ✨',
    '🏊 Yüzme sporcusu | 🌊 Deniz beni çağırıyor',
    '🎵 Müzisyen | 🎹 Piyano çalıyorum',
    '🧑‍🍳 Aşçıyım | 🍰 Tatlı yapmayı seviyorum',
    '🚴 Bisiklet tutkunu | 🏔️ Dağ bisikletçisiyim',
    'Data Scientist | Numbers tell stories 📊',
    '🎨 Grafik tasarımcı | 🖌️ Renklere aşığım',
    '🏀 Basketbol oynuyorum | ⛹️ Takım ruhu önemli',
    '🧘‍♀️ Yoga instructor | 🕉️ İç huzur rehberi',
    '🎬 Film yönetmeni | 🎥 Hikaye anlatıcısıyım',
    'Entrepreneur | Building dreams 🚀',
    '🌌 Astronomi meraklısı | 🔭 Yıldızları izliyorum',
    '🎪 Sirk sanatçısı | 🤹 Jonglörlük yapıyorum',
    '🧑‍🏫 Öğretmen | 📚 Eğitim tutkunu',
    '🏃‍♀️ Maraton koşucusu | 🏅 42 km aşkı',
    'Product Manager | Innovation lover 💡',
    '🧑‍💻 Full-stack developer | ☕ Code & Coffee',
    '🎺 Caz müzisyeni | 🎷 Saksafon çalıyorum',
    '🧗 Tırmanma sporcusu | ⛰️ Zirveye ulaşmak güzel',
    '🐕 Köpek eğitmeni | 🦴 Hayvanları eğitiyorum',
    'Architect | Designing the future 🏛️',
    '🌍 Çevre aktivisti | ♻️ Dünyayı kurtarıyorum',
    '🎨 Ressam | 🖼️ Tuvalimde hayat var',
    '🏄 Sörf yapıyorum | 🌊 Dalgalarla dans',
    '🧑‍🔬 Bilim insanı | 🔬 Araştırma tutkunu',
    'Journalist | Truth seeker 📰',
    '🎼 Besteci | 🎶 Müzik ruhumu ifade eder',
    '🏕️ Kamp sever | 🔥 Doğada huzur bulurum',
    '🧑‍⚕️ Doktor | 💉 İnsanlara yardım ediyorum',
    '🎯 Hedef odaklı | 💼 Başarı peşinde',
    'Photographer | Capturing moments 📷',
    '🍷 Şarap uzmanı | 🍇 Tadım yapmayı seviyorum',
    '🧘 Meditasyon | 🌸 İçsel huzur arıyorum',
    '🎪 Stand-up | 😂 Güldürmeyi seviyorum',
    'Life coach | Empowering others 🌟',
  ];

  // Örnek mesaj içerikleri
  final List<String> _sampleMessages = [
    'Merhaba! Nasılsın?',
    'Bugün ne yapıyorsun?',
    'Kahve içmeye gidelim mi?',
    'Çok güzel bir gün!',
    'Seni özledim 😊',
    'Toplantıya gelecek misin?',
    'Akşam müsait misin?',
    'Harika bir film izledim',
    'Teşekkür ederim!',
    'Görüşürüz 👋',
    'Hey! How are you?',
    'Long time no see!',
    'Let\'s catch up soon',
    'Great to hear from you!',
    'Thanks for your help',
  ];

  // Kullanıcı ID listesi (seed sırasında doldurulur)
  final List<String> _createdUserIds = [];

  /// ANA SEED FONKSİYONU - Tüm verileri sırayla yazar
  Future<void> seedDatabase() async {
    await _performSeed();
  }

  /// ALIAS: syncDatabase() - Kullanıcı isteği için alternatif isim
  Future<void> syncDatabase() async {
    await _performSeed();
  }

  /// İç seed implementasyonu
  Future<void> _performSeed() async {
    print('\n' + '=' * 60);
    print('🚀 VERİTABANI SEED İŞLEMİ BAŞLIYOR');
    print('=' * 60 + '\n');

    try {
      // 1. Kullanıcıları oluştur
      await _seedUsers();

      // 2. Arkadaşlıkları oluştur (accepted friendships)
      await _seedFriendships();

      // 3. Bekleyen arkadaşlık isteklerini oluştur
      await _seedFriendRequests();

      // 4. Engellenmiş kullanıcıları oluştur
      await _seedBlockedUsers();

      // 5. Mesaj geçmişini oluştur
      await _seedMessages();

      print('\n' + '=' * 60);
      print('✅ TÜM SEED İŞLEMLERİ BAŞARIYLA TAMAMLANDI!');
      print('=' * 60 + '\n');
    } catch (e, stackTrace) {
      print('\n' + '=' * 60);
      print('❌ SEED İŞLEMİ BAŞARISIZ!');
      print('Hata: $e');
      print('Stack: $stackTrace');
      print('=' * 60 + '\n');
      rethrow;
    }
  }

  /// 1. 50 Kullanıcı oluştur
  Future<void> _seedUsers() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('👥 ADIM 1: KULLANICILAR OLUŞTURULUYOR');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < _userNames.length; i++) {
      final userData = _userNames[i];
      final firstName = userData['first']!;
      final lastName = userData['last']!;
      final email = '${firstName.toLowerCase()}${i + 1}@test.com';
      const password = '123456';
      final displayName = '$firstName $lastName';

      try {
        print('[${i + 1}/50] 📝 $displayName ($email)');

        // 1. Firebase Authentication'da kullanıcı oluştur
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final firebaseUser = userCredential.user!;
        await firebaseUser.updateDisplayName(displayName);
        await firebaseUser.reload();

        // 2. Supabase'e sync et (bio ile birlikte)
        final randomBio = _sampleBios[_random.nextInt(_sampleBios.length)];

        await _supabase.syncUserFromFirebase(
          firebaseUid: firebaseUser.uid,
          email: email,
          username: '${firstName.toLowerCase()}${i + 1}',
          displayName: displayName,
          avatarUrl: null,
        );

        // 3. Bio'yu ayrıca güncelle (syncUserFromFirebase bio parametresi almıyor)
        await _client
            .from('users')
            .update({'bio': randomBio})
            .eq('id', firebaseUser.uid);

        _createdUserIds.add(firebaseUser.uid);
        successCount++;
        print('   ✅ Başarılı\n');

        // Rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        failCount++;
        print('   ❌ Hata: $e\n');

        // Rollback Firebase
        try {
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.email == email) {
            await currentUser.delete();
          }
        } catch (_) {}
      }
    }

    print('📊 KULLANICI SONUÇLARI:');
    print('   ✅ Başarılı: $successCount');
    print('   ❌ Başarısız: $failCount');
    print('   � Toplam: ${successCount + failCount}\n');
  }

  /// 2. Arkadaşlıkları oluştur (kabul edilmiş)
  Future<void> _seedFriendships() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🤝 ADIM 2: ARKADAŞLIKLAR OLUŞTURULUYOR');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    final List<Map<String, dynamic>> friendships = [];
    final Set<String> usedPairs = {};

    // Her kullanıcı için rastgele 3-8 arkadaş
    for (final userId in _createdUserIds) {
      final friendCount = _random.nextInt(6) + 3; // 3-8 arkadaş

      for (int i = 0; i < friendCount; i++) {
        final friendId =
            _createdUserIds[_random.nextInt(_createdUserIds.length)];

        // Kendisiyle arkadaş olmasın
        if (friendId == userId) continue;

        // Çift kontrolü (sıralı olarak)
        final pair = userId.compareTo(friendId) < 0
            ? '$userId-$friendId'
            : '$friendId-$userId';

        if (usedPairs.contains(pair)) continue;
        usedPairs.add(pair);

        final userId1 = userId.compareTo(friendId) < 0 ? userId : friendId;
        final userId2 = userId.compareTo(friendId) < 0 ? friendId : userId;

        friendships.add({
          'user_id_1': userId1,
          'user_id_2': userId2,
          'status': 'accepted',
          'requested_by': userId,
          'created_at': DateTime.now()
              .subtract(Duration(days: _random.nextInt(60)))
              .toIso8601String(),
        });
      }
    }

    // Batch insert
    if (friendships.isNotEmpty) {
      try {
        await _client.from('friendships').insert(friendships);
        print('✅ ${friendships.length} adet arkadaşlık DB\'ye yazıldı\n');
      } catch (e) {
        print('❌ Arkadaşlık yazma hatası: $e\n');
      }
    }
  }

  /// 3. Bekleyen arkadaşlık isteklerini oluştur
  Future<void> _seedFriendRequests() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📬 ADIM 3: ARKADAŞLIK İSTEKLERİ OLUŞTURULUYOR');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    final List<Map<String, dynamic>> friendRequests = [];
    final Set<String> usedPairs = {};

    // İlk 20 kullanıcı için rastgele pending istekler
    final requestCount = _createdUserIds.length > 20
        ? 20
        : _createdUserIds.length;
    for (int i = 0; i < requestCount; i++) {
      final senderId = _createdUserIds[i];
      final receiverId =
          _createdUserIds[_random.nextInt(_createdUserIds.length)];

      if (senderId == receiverId) continue;

      final pair = senderId.compareTo(receiverId) < 0
          ? '$senderId-$receiverId'
          : '$receiverId-$senderId';

      if (usedPairs.contains(pair)) continue;
      usedPairs.add(pair);

      final userId1 = senderId.compareTo(receiverId) < 0
          ? senderId
          : receiverId;
      final userId2 = senderId.compareTo(receiverId) < 0
          ? receiverId
          : senderId;

      friendRequests.add({
        'user_id_1': userId1,
        'user_id_2': userId2,
        'status': 'pending',
        'requested_by': senderId,
        'created_at': DateTime.now()
            .subtract(Duration(hours: _random.nextInt(72)))
            .toIso8601String(),
      });
    }

    // Batch insert
    if (friendRequests.isNotEmpty) {
      try {
        await _client.from('friendships').insert(friendRequests);
        print(
          '✅ ${friendRequests.length} adet arkadaşlık isteği DB\'ye yazıldı\n',
        );
      } catch (e) {
        print('❌ İstek yazma hatası: $e\n');
      }
    }
  }

  /// 4. Engellenmiş kullanıcıları oluştur
  Future<void> _seedBlockedUsers() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚫 ADIM 4: ENGELLENMİŞ KULLANICILAR OLUŞTURULUYOR');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    final List<Map<String, dynamic>> blockedUsers = [];

    // İlk 10 kullanıcı için rastgele 1-2 engelleme
    final blockCount = _createdUserIds.length > 10
        ? 10
        : _createdUserIds.length;
    for (int i = 0; i < blockCount; i++) {
      final blockerId = _createdUserIds[i];
      final blockedId =
          _createdUserIds[_random.nextInt(_createdUserIds.length)];

      if (blockerId == blockedId) continue;

      blockedUsers.add({
        'blocker_id': blockerId,
        'blocked_id': blockedId,
        'created_at': DateTime.now()
            .subtract(Duration(days: _random.nextInt(30)))
            .toIso8601String(),
      });
    }

    // Batch insert
    if (blockedUsers.isNotEmpty) {
      try {
        await _client.from('blocked_users').insert(blockedUsers);
        print('✅ ${blockedUsers.length} adet engelleme DB\'ye yazıldı\n');
      } catch (e) {
        print('❌ Engelleme yazma hatası: $e\n');
      }
    }
  }

  /// 5. Mesaj geçmişini oluştur
  Future<void> _seedMessages() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('💬 ADIM 5: MESAJLAR OLUŞTURULUYOR');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    final List<Map<String, dynamic>> messages = [];

    // İlk 30 kullanıcı çifti arasında rastgele konuşmalar
    final messageUserCount = _createdUserIds.length > 30
        ? 30
        : _createdUserIds.length;
    for (int i = 0; i < messageUserCount - 1; i += 2) {
      final user1Id = _createdUserIds[i];
      final user2Id = _createdUserIds[i + 1];

      // Her çift arasında 5-15 mesaj
      final msgCount = _random.nextInt(11) + 5; // 5-15
      for (int j = 0; j < msgCount; j++) {
        final senderId = _random.nextBool() ? user1Id : user2Id;
        final receiverId = senderId == user1Id ? user2Id : user1Id;

        messages.add({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'content': _sampleMessages[_random.nextInt(_sampleMessages.length)],
          'is_read': _random.nextBool(),
          'created_at': DateTime.now()
              .subtract(Duration(hours: _random.nextInt(168))) // Son 1 hafta
              .toIso8601String(),
        });
      }
    }

    // Batch insert (Supabase max 1000 row limit var, böl)
    if (messages.isNotEmpty) {
      try {
        // 500'lük parçalara böl
        for (int i = 0; i < messages.length; i += 500) {
          final chunk = messages.skip(i).take(500).toList();
          await _client.from('messages').insert(chunk);
          print(
            '   📤 ${chunk.length} mesaj yazıldı (Toplam: ${i + chunk.length}/${messages.length})',
          );
        }
        print('✅ ${messages.length} adet mesaj DB\'ye yazıldı\n');
      } catch (e) {
        print('❌ Mesaj yazma hatası: $e\n');
      }
    }
  }
}
