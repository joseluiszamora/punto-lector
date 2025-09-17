import 'package:flutter/material.dart';
import 'package:puntolector/data/models/author.dart';
import 'package:puntolector/features/authors/presentation/author_detail_page.dart';

class AuthorCircle extends StatelessWidget {
  final Author author;
  const AuthorCircle({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuthorDetailPage(author: author),
          ),
        );
      },
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            ClipOval(
              child: SizedBox(
                width: 56,
                height: 56,
                child:
                    (author.photoUrl != null && author.photoUrl!.isNotEmpty)
                        ? Image.network(
                          author.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.person_outline),
                              ),
                        )
                        : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person_outline),
                        ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              author.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
