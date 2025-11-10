import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int selectedTab = 0; // 0 = Favorites, 1 = Playlists
  bool isGridView = false;

  Widget buildTabButton(String text, int index) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: selectedTab == 0
                    ? "Search favorites..."
                    : "Search playlists...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.grid_view,
                      color: !isGridView ? Colors.grey : Colors.deepPurple),
                  onPressed: () {
                    setState(() {
                      isGridView = true;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.view_list,
                      color: isGridView ? Colors.grey : Colors.deepPurple),
                  onPressed: () {
                    setState(() {
                      isGridView = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAudioCard(BuildContext context, String title, String category, String duration, String imageUrl) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final isFavorite = audioProvider.isFavorite(title);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade300,
                child: const Icon(Icons.music_note, color: Colors.grey),
              );
            },
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trái tim yêu thích
            GestureDetector(
              onTap: () {
                audioProvider.toggleFavorite(title);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Nút play
            GestureDetector(
              onTap: () {
                audioProvider.setSong(
                  title,
                  artist: category,
                  thumbnail: imageUrl,
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF6750A4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildListContent(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    
    // Danh sách tất cả các bài hát
    final allSongs = [
      {
        'title': "The Science of Sleep",
        'category': "Health Insights",
        'duration': "23:40",
        'imageUrl': "https://picsum.photos/200?1",
      },
      {
        'title': "Productivity Techniques",
        'category': "Work Smarter",
        'duration': "30:30",
        'imageUrl': "https://picsum.photos/200?2",
      },
      {
        'title': "Exploring Mars",
        'category': "Space & Beyond",
        'duration': "36:55",
        'imageUrl': "https://picsum.photos/200?3",
      },
      {
        'title': "Introduction to Jazz",
        'category': "Music History",
        'duration': "27:25",
        'imageUrl': "https://picsum.photos/200?4",
      },
    ];

    // Lọc danh sách dựa trên tab được chọn
    final displaySongs = selectedTab == 0
        ? allSongs.where((song) => audioProvider.isFavorite(song['title'] as String)).toList()
        : allSongs;

    if (selectedTab == 0 && displaySongs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "No favorites yet",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tap the heart icon to add favorites",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: displaySongs.map((song) {
        return buildAudioCard(
          context,
          song['title'] as String,
          song['category'] as String,
          song['duration'] as String,
          song['imageUrl'] as String,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "Library",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  buildTabButton("Favorites", 0),
                  const SizedBox(width: 10),
                  buildTabButton("Playlists", 1),
                ],
              ),
            ),
            buildSearchBar(),
            buildListContent(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
