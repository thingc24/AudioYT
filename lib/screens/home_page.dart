import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(onPressed: () {}, child: const Text("See all")),
        ],
      ),
    );
  }

  Widget buildAudioCard(String title, String category, String duration) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            'https://picsum.photos/200',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(category),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(duration, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.deepPurple),
              onPressed: () {

              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMiniPlayer() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://picsum.photos/100',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text("Tech Podcast",
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () {
              //pause
            },
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Good afternoon",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("What would you like to listen to today?"),
                ],
              ),
            ),

            // Continue Listening
            buildSectionTitle("Continue Listening"),
            buildAudioCard("Financial Planning for Beginners",
                "Money Matters", "27:25"),
            buildAudioCard(
                "Effective Communication", "Career Growth", "30:30"),
            buildAudioCard("Deep Dive into Quantum Physics",
                "Science Explained", "37:25"),

            // Trending Now
            buildSectionTitle("Trending Now"),
            buildAudioCard("Financial Planning for Beginners",
                "Money Matters", "27:25"),
            buildAudioCard(
                "Effective Communication", "Career Growth", "30:30"),
            buildAudioCard("Deep Dive into Quantum Physics",
                "Science Explained", "37:25"),

            const SizedBox(height: 80),
          ],
        ),
      ),

      // Mini Player
      //bottomSheet: buildMiniPlayer(),
    );
  }
}
