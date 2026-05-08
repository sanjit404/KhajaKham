import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String description;
  final double price;
  final VoidCallback onAddToCart;
  final bool isAdded; 

  const MenuCard({
    super.key,
    this.imageUrl,
    required this.name,
    required this.description,
    required this.price,
    required this.onAddToCart,
    this.isAdded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      surfaceTintColor: Colors.orange,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: imageUrl != null && imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.fastfood, size: 50),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text("Rs.$price", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isAdded ? Colors.green : Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onAddToCart,
          child: Text(isAdded ? "Added" : "Add"),
        ),
      ),
    );
  }
}
