import 'package:equatable/equatable.dart';

class SubjectModel extends Equatable {
  final String id;
  final String name; // e.g. "Mathématiques", "Physique"
  final double coefficient;
  final String description;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.coefficient,
    required this.description,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SubjectModel(
      id: documentId,
      name: map['name'] ?? '',
      coefficient: (map['coefficient'] ?? 1.0).toDouble(),
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'coefficient': coefficient,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, name, coefficient, description];
}
