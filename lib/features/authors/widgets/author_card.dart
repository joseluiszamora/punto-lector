import 'package:flutter/material.dart';
import '../../../data/models/author.dart';

class AuthorCard extends StatelessWidget {
  final Author author;
  final VoidCallback onTap;

  const AuthorCard({super.key, required this.author, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Avatar del autor
            Hero(
              tag: 'author-${author.id}',
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child:
                      author.photoUrl?.isNotEmpty == true
                          ? Image.network(
                            author.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    _buildPlaceholderAvatar(context),
                          )
                          : _buildPlaceholderAvatar(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Nombre del autor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                author.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            // Información adicional
            if (author.birthDate != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getAgeText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Bio corta
            if (author.bio?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  author.bio!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          author.name.isNotEmpty ? author.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getAgeText() {
    if (author.birthDate == null) return '';

    final now = DateTime.now();
    final endDate = author.deathDate ?? now;
    final age = endDate.year - author.birthDate!.year;

    if (author.deathDate != null) {
      return '$age años (†${author.deathDate!.year})';
    } else {
      return '$age años';
    }
  }
}
