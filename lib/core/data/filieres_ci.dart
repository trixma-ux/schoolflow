class SubjectDef {
  final String id;
  final String name;
  final double coefficient;
  const SubjectDef({required this.id, required this.name, required this.coefficient});
}

class FiliereDef {
  final String id;
  final String name;
  final String description;
  final List<SubjectDef> subjects;
  const FiliereDef({required this.id, required this.name, required this.description, required this.subjects});
}

const List<FiliereDef> filieresCi = [
  FiliereDef(
    id: 'A',
    name: 'Série A',
    description: 'Lettres & Sciences Humaines',
    subjects: [
      SubjectDef(id: 'A_fr', name: 'Français', coefficient: 3.0),
      SubjectDef(id: 'A_philo', name: 'Philosophie', coefficient: 3.0),
      SubjectDef(id: 'A_hist', name: 'Histoire-Géographie', coefficient: 3.0),
      SubjectDef(id: 'A_en', name: 'Anglais', coefficient: 2.0),
      SubjectDef(id: 'A_es', name: 'Espagnol', coefficient: 2.0),
      SubjectDef(id: 'A_arts', name: 'Arts Plastiques', coefficient: 2.0),
      SubjectDef(id: 'A_eps', name: 'EPS', coefficient: 1.0),
    ],
  ),
  FiliereDef(
    id: 'B',
    name: 'Série B',
    description: 'Sciences Économiques & Sociales',
    subjects: [
      SubjectDef(id: 'B_maths', name: 'Mathématiques', coefficient: 3.0),
      SubjectDef(id: 'B_ses', name: 'Sciences Éco. & Sociales', coefficient: 4.0),
      SubjectDef(id: 'B_compta', name: 'Comptabilité & Gestion', coefficient: 3.0),
      SubjectDef(id: 'B_en', name: 'Anglais', coefficient: 2.0),
      SubjectDef(id: 'B_fr', name: 'Français', coefficient: 3.0),
      SubjectDef(id: 'B_hist', name: 'Histoire-Géographie', coefficient: 2.0),
      SubjectDef(id: 'B_droit', name: 'Droit', coefficient: 2.0),
      SubjectDef(id: 'B_eps', name: 'EPS', coefficient: 1.0),
    ],
  ),
  FiliereDef(
    id: 'C',
    name: 'Série C',
    description: 'Mathématiques & Sciences Physiques',
    subjects: [
      SubjectDef(id: 'C_maths', name: 'Mathématiques', coefficient: 7.0),
      SubjectDef(id: 'C_phy', name: 'Physique-Chimie', coefficient: 5.0),
      SubjectDef(id: 'C_svt', name: 'SVT', coefficient: 2.0),
      SubjectDef(id: 'C_en', name: 'Anglais', coefficient: 2.0),
      SubjectDef(id: 'C_fr', name: 'Français', coefficient: 2.0),
      SubjectDef(id: 'C_philo', name: 'Philosophie', coefficient: 1.0),
      SubjectDef(id: 'C_eps', name: 'EPS', coefficient: 1.0),
    ],
  ),
  FiliereDef(
    id: 'D',
    name: 'Série D',
    description: 'Sciences de la Vie & de la Terre',
    subjects: [
      SubjectDef(id: 'D_svt', name: 'SVT', coefficient: 5.0),
      SubjectDef(id: 'D_maths', name: 'Mathématiques', coefficient: 4.0),
      SubjectDef(id: 'D_phy', name: 'Physique-Chimie', coefficient: 3.0),
      SubjectDef(id: 'D_chim', name: 'Chimie', coefficient: 2.0),
      SubjectDef(id: 'D_en', name: 'Anglais', coefficient: 2.0),
      SubjectDef(id: 'D_fr', name: 'Français', coefficient: 2.0),
      SubjectDef(id: 'D_philo', name: 'Philosophie', coefficient: 1.0),
      SubjectDef(id: 'D_eps', name: 'EPS', coefficient: 1.0),
    ],
  ),
  FiliereDef(
    id: 'E',
    name: 'Série E',
    description: 'Mathématiques & Technique',
    subjects: [
      SubjectDef(id: 'E_maths', name: 'Mathématiques', coefficient: 6.0),
      SubjectDef(id: 'E_phys', name: 'Sciences Physiques', coefficient: 4.0),
      SubjectDef(id: 'E_si', name: "Sciences de l'Ingénieur", coefficient: 4.0),
      SubjectDef(id: 'E_tech', name: 'Technologie', coefficient: 3.0),
      SubjectDef(id: 'E_en', name: 'Anglais', coefficient: 2.0),
      SubjectDef(id: 'E_fr', name: 'Français', coefficient: 1.0),
      SubjectDef(id: 'E_eps', name: 'EPS', coefficient: 1.0),
    ],
  ),
  FiliereDef(
    id: 'G1',
    name: 'Série G1',
    description: 'Techniques Administratives',
    subjects: [
      SubjectDef(id: 'G1_compta', name: 'Comptabilité & Gestion', coefficient: 5.0),
      SubjectDef(id: 'G1_info', name: 'Informatique de Gestion', coefficient: 3.0),
      SubjectDef(id: 'G1_eco', name: 'Économie', coefficient: 3.0),
      SubjectDef(id: 'G1_droit', name: 'Droit', coefficient: 3.0),
      SubjectDef(id: 'G1_maths', name: 'Mathématiques', coefficient: 2.0),
      SubjectDef(id: 'G1_en', name: 'Anglais', coefficient: 2.0),
      SubjectDef(id: 'G1_fr', name: 'Français', coefficient: 2.0),
      SubjectDef(id: 'G1_eps', name: 'EPS', coefficient: 1.0),
    ],
  ),
  FiliereDef(
    id: 'G2',
    name: 'Série G2',
    description: 'Techniques Commerciales',
    subjects: [
      SubjectDef(id: 'G2_com', name: 'Commerce & Marketing', coefficient: 5.0),
      SubjectDef(id: 'G2_compta', name: 'Comptabilité', coefficient: 3.0),
      SubjectDef(id: 'G2_eco', name: 'Économie', coefficient: 3.0),
      SubjectDef(id: 'G2_droit', name: 'Droit Commercial', coefficient: 2.0),
      SubjectDef(id: 'G2_maths', name: 'Mathématiques', coefficient: 2.0),
      SubjectDef(id: 'G2_en', name: 'Anglais', coefficient: 2.0),
      SubjectDef(id: 'G2_fr', name: 'Français', coefficient: 2.0),
      SubjectDef(id: 'G2_eps', name: 'EPS', coefficient: 1.0),
    ],
  ),
  FiliereDef(
    id: 'T1',
    name: 'Série T1',
    description: 'Génie Civil',
    subjects: [
      SubjectDef(id: 'T1_si', name: 'Génie Civil', coefficient: 6.0),
      SubjectDef(id: 'T1_maths', name: 'Mathématiques', coefficient: 4.0),
      SubjectDef(id: 'T1_phy', name: 'Physique-Chimie', coefficient: 3.0),
      SubjectDef(id: 'T1_bat', name: 'Technologie du Bâtiment', coefficient: 3.0),
      SubjectDef(id: 'T1_en', name: 'Anglais', coefficient: 2.0),
      SubjectDef(id: 'T1_fr', name: 'Français', coefficient: 1.0),
      SubjectDef(id: 'T1_eps', name: 'EPS', coefficient: 1.0),
    ],
  ),
  FiliereDef(
    id: 'T2',
    name: 'Série T2',
    description: 'Génie Électrique',
    subjects: [
      SubjectDef(id: 'T2_elec', name: "Sciences de l'Ingénieur Électrique", coefficient: 6.0),
      SubjectDef(id: 'T2_maths', name: 'Mathématiques', coefficient: 4.0),
      SubjectDef(id: 'T2_phy', name: 'Physique-Chimie', coefficient: 3.0),
      SubjectDef(id: 'T2_elecpro', name: 'Électronique & Électrotechnique', coefficient: 3.0),
      SubjectDef(id: 'T2_en', name: 'Anglais', coefficient: 2.0),
      SubjectDef(id: 'T2_fr', name: 'Français', coefficient: 1.0),
      SubjectDef(id: 'T2_eps', name: 'EPS', coefficient: 1.0),
    ],
  ),
  FiliereDef(
    id: 'T3',
    name: 'Série T3',
    description: 'Génie Mécanique',
    subjects: [
      SubjectDef(id: 'T3_meca', name: "Sciences de l'Ingénieur Mécanique", coefficient: 6.0),
      SubjectDef(id: 'T3_maths', name: 'Mathématiques', coefficient: 4.0),
      SubjectDef(id: 'T3_phy', name: 'Physique-Chimie', coefficient: 3.0),
      SubjectDef(id: 'T3_tech', name: 'Technologie Mécanique', coefficient: 3.0),
      SubjectDef(id: 'T3_en', name: 'Anglais', coefficient: 2.0),
      SubjectDef(id: 'T3_fr', name: 'Français', coefficient: 1.0),
      SubjectDef(id: 'T3_eps', name: 'EPS', coefficient: 1.0),
    ],
  ),
];
