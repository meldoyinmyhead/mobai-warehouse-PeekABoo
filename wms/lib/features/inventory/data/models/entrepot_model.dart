class EntrepotModel {
  final int? idEntrepot;
  final String codeEntrepot;
  final String nomEntrepot;
  final String ville;
  final bool actif;

  EntrepotModel({
    this.idEntrepot,
    required this.codeEntrepot,
    required this.nomEntrepot,
    required this.ville,
    required this.actif,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_entrepot': idEntrepot,
      'code_entrepot': codeEntrepot,
      'nom_entrepot': nomEntrepot,
      'ville': ville,
      'actif': actif ? 1 : 0,
    };
  }

  factory EntrepotModel.fromMap(Map<String, dynamic> map) {
    return EntrepotModel(
      idEntrepot: map['id_entrepot'],
      codeEntrepot: map['code_entrepot'],
      nomEntrepot: map['nom_entrepot'],
      ville: map['ville'],
      actif: map['actif'] == 1,
    );
  }
}
