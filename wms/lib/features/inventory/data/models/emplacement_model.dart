class EmplacementModel {
  final int? idEmplacement;
  final int idEntrepot;
  final String codeEmplacement;
  final String typeEmplacement;
  final String zone;
  final String allee;
  final String travay;
  final String niveau;
  final String position;
  final String statut;

  EmplacementModel({
    this.idEmplacement,
    required this.idEntrepot,
    required this.codeEmplacement,
    required this.typeEmplacement,
    required this.zone,
    required this.allee,
    required this.travay,
    required this.niveau,
    required this.position,
    required this.statut,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_emplacement': idEmplacement,
      'id_entrepot': idEntrepot,
      'code_emplacement': codeEmplacement,
      'type_emplacement': typeEmplacement,
      'zone': zone,
      'allee': allee,
      'travay': travay,
      'niveau': niveau,
      'position': position,
      'statut': statut,
    };
  }

  factory EmplacementModel.fromMap(Map<String, dynamic> map) {
    return EmplacementModel(
      idEmplacement: map['id_emplacement'],
      idEntrepot: map['id_entrepot'],
      codeEmplacement: map['code_emplacement'],
      typeEmplacement: map['type_emplacement'],
      zone: map['zone'],
      allee: map['allee'],
      travay: map['travay'],
      niveau: map['niveau'],
      position: map['position'],
      statut: map['statut'],
    );
  }
}
