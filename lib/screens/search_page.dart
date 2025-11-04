import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  Widget buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for audio content...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget buildRecentSearch(String text) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(text),
        trailing: const Icon(Icons.close, size: 20),
        onTap: () {},
      ),
    );
  }

  Widget buildCategoryCard(String title) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text("Popular content",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPopularCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text("Popular Categories",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Row(
            children: [
              buildCategoryCard("Technology"),
              buildCategoryCard("Business"),
            ],
          ),
          Row(
            children: [
              buildCategoryCard("Science"),
              buildCategoryCard("Health"),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text("Search",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            buildSearchField(),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("Recent Searches",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            buildRecentSearch("meditation music"),
            buildRecentSearch("tech podcast"),
            buildRecentSearch("history documentary"),
            buildRecentSearch("cooking tutorial"),

            buildPopularCategories(),
          ],
        ),
      ),
    );
  }
}
