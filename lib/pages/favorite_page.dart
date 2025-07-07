import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  // Mock favorite data
  final List<Map<String, dynamic>> _favorites = [
    {
      'id': '1',
      'title': 'Diamond Ring',
      'image': 'assets/figure/1/p/1_p_2025_06_24_1.png',
      'date': '2025-01-15',
      'description': 'Classic six-prong diamond ring, dazzling and brilliant',
    },
    {
      'id': '2',
      'title': 'Pearl Necklace',
      'image': 'assets/figure/2/p/2_p_2025_06_24_1.png',
      'date': '2025-01-14',
      'description': 'Natural freshwater pearls, elegant and noble',
    },
    {
      'id': '3',
      'title': 'Ruby Earrings',
      'image': 'assets/figure/3/p/3_p_2025_06_24_1.png',
      'date': '2025-01-13',
      'description': 'Burmese rubies, passionate and fiery',
    },
    {
      'id': '4',
      'title': 'Sapphire Bracelet',
      'image': 'assets/figure/4/p/4_p_2025_06_24_1.png',
      'date': '2025-01-12',
      'description': 'Sri Lankan sapphires, deep and mesmerizing',
    },
    {
      'id': '5',
      'title': 'Emerald Ring',
      'image': 'assets/figure/5/p/5_p_2025_06_24_1.png',
      'date': '2025-01-11',
      'description': 'Colombian emeralds, natural and fresh',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Favorites',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: Container(), // 移除返回按钮
      ),
      body: _favorites.isEmpty ? _buildEmptyState() : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Favorites Yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your photographed jewelry will be saved here automatically',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final favorite = _favorites[index];
        return _buildFavoriteItem(favorite, index);
      },
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> favorite, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片部分
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Image.asset(
                favorite['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),

          // 内容部分
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        favorite['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeFavorite(favorite['id']),
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  favorite['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      favorite['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _shareFavorite(favorite),
                      icon: Icon(
                        Icons.share,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _removeFavorite(String id) {
    setState(() {
      _favorites.removeWhere((item) => item['id'] == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from favorites'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareFavorite(Map<String, dynamic> favorite) {
    try {
      // Create share text with jewelry information
      final shareText = '''
${favorite['title']}

${favorite['description']}

Photographed on: ${favorite['date']}

Shared from Milya - Your Jewelry Photography App
      '''
          .trim();

      // Share using native iOS share sheet
      Share.share(
        shareText,
        subject: 'Check out this beautiful jewelry: ${favorite['title']}',
      );
    } catch (e) {
      // Fallback if sharing fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: ${favorite['title']}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
