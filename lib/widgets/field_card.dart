import 'package:flutter/material.dart';
import '../models/field.dart';

class FieldCard extends StatelessWidget {
  final Field field;
  final VoidCallback onTap;
  const FieldCard({super.key, required this.field, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(field.name),
        subtitle: Text('Buka ${field.openHour} - Tutup ${field.closeHour}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
