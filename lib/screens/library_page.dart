import 'package:flutter/material.dart';

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

  Widget buildAudioCard(String title, String category, String duration, String imageUrl) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(imageUrl, width: 55, height: 55, fit: BoxFit.cover),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(category),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(duration, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            const Icon(Icons.favorite, color: Colors.pink),
            const SizedBox(width: 8),
            const Icon(Icons.play_circle_fill, color: Colors.deepPurple),
          ],
        ),
      ),
    );
  }

  Widget buildListContent() {
    return Column(
      children: [
        buildAudioCard(
          "The Science of Sleep",
          "Health Insights",
          "23:40",
          "https://picsum.photos/200?1",
        ),
        buildAudioCard(
          "Productivity Techniques",
          "Work Smarter",
          "30:30",
          "https://picsum.photos/200?2",
        ),
        buildAudioCard(
          "Exploring Mars",
          "Space & Beyond",
          "36:55",
          "https://picsum.photos/200?3",
        ),
        buildAudioCard(
          "Introduction to Jazz",
          "Music History",
          "27:25",
          "https://picsum.photos/200?4",
        ),
      ],
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
            buildListContent(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
