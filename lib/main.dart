import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const CineWorldApp());
}

class CineWorldApp extends StatelessWidget {
  const CineWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineWorld',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        primaryColor: const Color(0xFFE50914),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE50914),
          secondary: Color(0xFFFFD700),
          surface: Color(0xFF1F1F35),
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      ),
      home: const HomeScreen(),
    );
  }
}

// ================= API SERVICE =================
class ApiService {
  static const String apiKey = '802b2c4b88ea1183e50e6b358528611d'; // مفتاح تجريبي للـ TMDB API
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static Future<List<dynamic>> fetchTrending(String mediaType, {String lang = 'ar-SA'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trending/$mediaType/week?api_key=$apiKey&language=$lang'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['results'];
    }
    return [];
  }

  static Future<List<dynamic>> searchMedia(String query, {String lang = 'ar-SA'}) async {
    if (query.isEmpty) return [];
    final response = await http.get(
      Uri.parse('$baseUrl/search/multi?api_key=$apiKey&language=$lang&query=$query'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['results'];
    }
    return [];
  }
}

// ================= HOME SCREEN =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String currentLang = 'ar-SA';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override:
  Widget build(BuildContext context) {
    bool isArabic = currentLang.startsWith('ar');

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'CINEWORLD',
            style: GoogleFonts.blackOpsOne(
              fontSize: 26,
              color: const Color(0xFFE50914),
              letterSpacing: 2,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, size: 28),
              onPressed: () {
                showSearch(context: context, delegate: MediaSearchDelegate(lang: currentLang));
              },
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  currentLang = isArabic ? 'en-US' : 'ar-SA';
                });
              },
              child: Text(
                isArabic ? 'EN' : 'عربي',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFE50914),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: isArabic ? 'الأفلام' : 'Movies'),
              Tab(text: isArabic ? 'المسلسلات' : 'TV Series'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            MediaListView(mediaType: 'movie', lang: currentLang),
            MediaListView(mediaType: 'tv', lang: currentLang),
          ],
        ),
      ),
    );
  }
}

// ================= MEDIA LIST VIEW =================
class MediaListView extends StatelessWidget {
  final String mediaType;
  final String lang;

  const MediaListView({super.key, required this.mediaType, required this.lang});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.fetchTrending(mediaType, lang: lang),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              lang.startsWith('ar') ? 'حدث خطأ أثناء تحميل البيانات' : 'Failed to load content',
              style: const TextStyle(color: Colors.white54),
            ),
          );
        }

        final items = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return MediaCard(item: item, mediaType: mediaType);
          },
        );
      },
    );
  }
}

// ================= MEDIA CARD =================
class MediaCard extends StatelessWidget {
  final dynamic item;
  final String mediaType;

  const MediaCard({super.key, required this.item, required this.mediaType});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? item['name'] ?? '';
    final posterPath = item['poster_path'];
    final rating = (item['vote_average'] as num?)?.toStringAsFixed(1) ?? 'N/A';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(item: item, mediaType: mediaType),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: const Color(0xFF1F1F35),
          child: Stack(
            children: [
              Positioned.fill(
                child: posterPath != null
                    ? CachedNetworkImage(
                        imageUrl: '${ApiService.imageBaseUrl}$posterPath',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.black26),
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                      )
                    : Container(color: Colors.black26, child: const Icon(Icons.movie, size: 50)),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= DETAIL SCREEN =================
class DetailScreen extends StatelessWidget {
  final dynamic item;
  final String mediaType;

  const DetailScreen({super.key, required this.item, required this.mediaType});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? item['name'] ?? '';
    final overview = item['overview'] ?? '';
    final posterPath = item['poster_path'];
    final backdropPath = item['backdrop_path'];
    final rating = (item['vote_average'] as num?)?.toStringAsFixed(1) ?? 'N/A';
    final releaseDate = item['release_date'] ?? item['first_air_date'] ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F1E),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  backdropPath != null
                      ? CachedNetworkImage(
                          imageUrl: '${ApiService.imageBaseUrl}$backdropPath',
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey[900]),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xFF0F0F1E)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          mediaType.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
                      const SizedBox(width: 4),
                      Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      Text(releaseDate, style: const TextStyle(color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('جاري فتح مشغل الفيديو...')),
                      );
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text('مشاهدة الآن / Watch Now', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'القصة / Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    overview.isEmpty ? 'لا توجد تفاصيل متاحة.' : overview,
                    style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= SEARCH DELEGATE =================
class MediaSearchDelegate extends SearchDelegate {
  final String lang;

  MediaSearchDelegate({required this.lang});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1F1F35)),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Text(
          lang.startsWith('ar') ? 'ابحث عن أي فيلم أو مسلسل...' : 'Search for any movie or TV show...',
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: ApiService.searchMedia(query, lang: lang),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              lang.startsWith('ar') ? 'لا توجد نتائج' : 'No results found',
              style: const TextStyle(color: Colors.white54),
            ),
          );
        }

        final results = snapshot.data!;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            final title = item['title'] ?? item['name'] ?? '';
            final posterPath = item['poster_path'];
            final mediaType = item['media_type'] ?? 'movie';

            return ListTile(
              leading: posterPath != null
                  ? CachedNetworkImage(
                      imageUrl: '${ApiService.imageBaseUrl}$posterPath',
                      width: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.movie, size: 50),
              title: Text(title, style: const TextStyle(color: Colors.white)),
              subtitle: Text(mediaType.toUpperCase(), style: const TextStyle(color: Colors.white38)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(item: item, mediaType: mediaType),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
