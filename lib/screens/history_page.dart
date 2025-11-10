import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search history...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            date,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHistoryCard(BuildContext context, {
    required String title,
    required String category,
    required String startTime,
    required String duration,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                const Icon(Icons.access_time,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  startTime,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(width: 8),
                const Text("•",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                Text(
                  duration,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () {
            final audioProvider = Provider.of<AudioProvider>(context, listen: false);
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
      ),
    );
  }

  Widget buildHistoryList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle("15/5/2023"),
        buildHistoryCard(
          context,
          title: "The Future of Artificial Intelligence",
          category: "Tech Insights",
          startTime: "21:30",
          duration: "30:45",
          imageUrl: "https://picsum.photos/200?1",
        ),
        buildHistoryCard(
          context,
          title: "Mindfulness Meditation",
          category: "Mindful Living",
          startTime: "17:15",
          duration: "20:30",
          imageUrl: "https://picsum.photos/200?2",
        ),
        buildHistoryCard(
          context,
          title: "Ancient Roman History",
          category: "History Uncovered",
          startTime: "01:45",
          duration: "40:10",
          imageUrl: "https://picsum.photos/200?3",
        ),
        buildSectionTitle("14/5/2023"),
        buildHistoryCard(
          context,
          title: "Italian Pasta Recipes",
          category: "Culinary Masters",
          startTime: "19:20",
          duration: "25:20",
          imageUrl: "https://picsum.photos/200?4",
        ),
        buildSectionTitle("13/5/2023"),
        buildHistoryCard(
          context,
          title: "Investment Strategies",
          category: "Money Matters",
          startTime: "16:10",
          duration: "27:25",
          imageUrl: "https://picsum.photos/200?5",
        ),
      ],
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            "History",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.black54),
              SizedBox(width: 6),
              Text(
                "Clear History",
                style: TextStyle(color: Colors.black87, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: ListView(
          children: [
            buildHeader(),
            buildSearchBar(),
            buildHistoryList(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
