import 'package:equatable/equatable.dart';
import '../../core/data/filieres_ci.dart';

class ClassModel extends Equatable {
  final String id;
  final String name; // e.g. "Terminale C1"
  final String academicYear; // e.g. "2023-2024"
  final List<String> teacherIds;
  final List<String> studentIds;

  /// Filière (série CI : A, B, C, D, E, G1, G2, T1, T2, T3) de la classe.
  /// Les élèves inscrits dans cette filière y sont affectés automatiquement.
  final String? filiere;

  /// Effectif maximum (null = pas de limite).
  final int? capacity;

  const ClassModel({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.teacherIds,
    required this.studentIds,
    this.filiere,
    this.capacity,
  });

  bool get isFull => capacity != null && studentIds.length >= capacity!;

  factory ClassModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawCapacity = map['capacity'];
    final filiere = map['filiere'];
    return ClassModel(
      id: documentId,
      name: map['name'] ?? '',
      academicYear: map['academicYear'] ?? '',
      teacherIds: map['teacherIds'] != null ? List<String>.from(map['teacherIds']) : [],
      studentIds: map['studentIds'] != null ? List<String>.from(map['studentIds']) : [],
      filiere: filiere is String ? (canonicalFiliere(filiere) ?? (filiere.isNotEmpty ? filiere : null)) : null,
      capacity: rawCapacity is num && rawCapacity > 0 ? rawCapacity.toInt() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'academicYear': academicYear,
      'teacherIds': teacherIds,
      'studentIds': studentIds,
      if (canonicalFiliere(filiere) != null) 'filiere': canonicalFiliere(filiere),
      if (capacity != null) 'capacity': capacity,
    };
  }

  @override
  List<Object?> get props => [id, name, academicYear, teacherIds, studentIds, filiere, capacity];
}
