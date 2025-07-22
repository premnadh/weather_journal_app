import 'package:hive/hive.dart';
import 'weather.dart';
part 'journal_entry.g.dart';

@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final String text;
  @HiveField(3)
  final Weather weather;
  @HiveField(4)
  final DateTime? editedAt;

  JournalEntry({
    required this.id,
    required this.date,
    required this.text,
    required this.weather,
    this.editedAt,
  });
}
