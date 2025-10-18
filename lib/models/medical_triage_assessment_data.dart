class MedicalTriageAssessmentData {
  final int age;
  final String sex;
  final String chestPainType;
  final int chestPainDuration;
  final String shortnessOfBreathLevel;
  final String palpitationType;
  final int systolicBP;
  final int diastolicBP;
  final int heartRate;
  final int oxygenSaturation;
  final double temperature;
  final bool hasHeartAttack;
  final bool hasStroke;
  final bool hasDiabetes;
  final bool hasHighBloodPressure;
  final bool hasHighCholesterol;
  final bool smokes;
  final bool drinksAlcohol;
  final bool exercisesRegularly;
  final String stressLevel;
  final bool hasSyncope;
  final bool hasFainting;

  MedicalTriageAssessmentData({
    required this.age,
    required this.sex,
    required this.chestPainType,
    required this.chestPainDuration,
    required this.shortnessOfBreathLevel,
    required this.palpitationType,
    required this.systolicBP,
    required this.diastolicBP,
    required this.heartRate,
    required this.oxygenSaturation,
    required this.temperature,
    required this.hasHeartAttack,
    required this.hasStroke,
    required this.hasDiabetes,
    required this.hasHighBloodPressure,
    required this.hasHighCholesterol,
    required this.smokes,
    required this.drinksAlcohol,
    required this.exercisesRegularly,
    required this.stressLevel,
    required this.hasSyncope,
    required this.hasFainting,
  });

  factory MedicalTriageAssessmentData.fromMap(Map<String, dynamic> map) {
    return MedicalTriageAssessmentData(
      age: int.tryParse(map['age']?.toString() ?? '0') ?? 0,
      sex: map['sex']?.toString() ?? 'Male',
      chestPainType: map['chestPainType']?.toString() ?? 'No chest pain',
      chestPainDuration: int.tryParse(map['chestPainDuration']?.toString() ?? '0') ?? 0,
      shortnessOfBreathLevel: map['shortnessOfBreath']?.toString() ?? 'None',
      palpitationType: map['palpitations']?.toString() ?? 'No palpitations',
      systolicBP: int.tryParse(map['systolicBP']?.toString() ?? '120') ?? 120,
      diastolicBP: int.tryParse(map['diastolicBP']?.toString() ?? '80') ?? 80,
      heartRate: int.tryParse(map['heartRate']?.toString() ?? '70') ?? 70,
      oxygenSaturation: int.tryParse(map['oxygenSaturation']?.toString() ?? '98') ?? 98,
      temperature: double.tryParse(map['temperature']?.toString() ?? '98.6') ?? 98.6,
      hasHeartAttack: map['hasHeartAttack'] == true || map['hasHeartAttack'] == 'true',
      hasStroke: map['hasStroke'] == true || map['hasStroke'] == 'true',
      hasDiabetes: map['hasDiabetes'] == true || map['hasDiabetes'] == 'true',
      hasHighBloodPressure: map['hasHighBloodPressure'] == true || map['hasHighBloodPressure'] == 'true',
      hasHighCholesterol: map['hasHighCholesterol'] == true || map['hasHighCholesterol'] == 'true',
      smokes: map['smokes'] == true || map['smokes'] == 'true',
      drinksAlcohol: map['drinksAlcohol'] == true || map['drinksAlcohol'] == 'true',
      exercisesRegularly: map['exercisesRegularly'] == true || map['exercisesRegularly'] == 'true',
      stressLevel: map['stressLevel']?.toString() ?? 'low',
      hasSyncope: map['syncope'] == true || map['syncope'] == 'true',
      hasFainting: map['fainting'] == true || map['fainting'] == 'true',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'age': age,
      'sex': sex,
      'chestPainType': chestPainType,
      'chestPainDuration': chestPainDuration,
      'shortnessOfBreath': shortnessOfBreathLevel,
      'palpitations': palpitationType,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'heartRate': heartRate,
      'oxygenSaturation': oxygenSaturation,
      'temperature': temperature,
      'hasHeartAttack': hasHeartAttack,
      'hasStroke': hasStroke,
      'hasDiabetes': hasDiabetes,
      'hasHighBloodPressure': hasHighBloodPressure,
      'hasHighCholesterol': hasHighCholesterol,
      'smokes': smokes,
      'drinksAlcohol': drinksAlcohol,
      'exercisesRegularly': exercisesRegularly,
      'stressLevel': stressLevel,
      'syncope': hasSyncope,
      'fainting': hasFainting,
    };
  }
}
