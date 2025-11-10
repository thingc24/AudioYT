import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

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

  Widget buildAudioCard(BuildContext context, String title, String category, String duration, {String? imageUrl}) {
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
            imageUrl ?? 'https://picsum.photos/200?$title',
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
        trailing: GestureDetector(
          onTap: () {
            final audioProvider = Provider.of<AudioProvider>(context, listen: false);
            audioProvider.setSong(
              title,
              artist: category,
              thumbnail: imageUrl ?? 'https://picsum.photos/200?$title',
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
            buildAudioCard(
              context,
              "Financial Planning for Beginners",
              "Money Matters",
              "27:25",
              imageUrl: "https://picsum.photos/200?1",
            ),
            buildAudioCard(
              context,
              "Effective Communication",
              "Career Growth",
              "30:30",
              imageUrl: "https://picsum.photos/200?2",
            ),
            buildAudioCard(
              context,
              "Deep Dive into Quantum Physics",
              "Science Explained",
              "37:25",
              imageUrl: "https://picsum.photos/200?3",
            ),

            // Trending Now
            buildSectionTitle("Trending Now"),
            buildAudioCard(
              context,
              "Financial Planning for Beginners",
              "Money Matters",
              "27:25",
              imageUrl: "https://picsum.photos/200?4",
            ),
            buildAudioCard(
              context,
              "Effective Communication",
              "Career Growth",
              "30:30",
              imageUrl: "https://picsum.photos/200?5",
            ),
            buildAudioCard(
              context,
              "Deep Dive into Quantum Physics",
              "Science Explained",
              "37:25",
              imageUrl: "https://picsum.photos/200?6",
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      // Mini Player
      //bottomSheet: buildMiniPlayer(),
    );
  }
}
