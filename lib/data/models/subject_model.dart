import 'package:equatable/equatable.dart';

class SubjectModel extends Equatable {
  final String id;
  final String name;
  final double coefficient;
  final String description;
  final String filiere;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.coefficient,
    required this.description,
    required this.filiere,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SubjectModel(
      id: documentId,
      name: map['name'] ?? '',
      coefficient: (map['coefficient'] ?? 1.0).toDouble(),
      description: map['description'] ?? '',
      filiere: map['filiere'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'coefficient': coefficient,
      'description': description,
      'filiere': filiere,
    };
  }

  @override
  List<Object?> get props => [id, name, coefficient, description, filiere];
}
