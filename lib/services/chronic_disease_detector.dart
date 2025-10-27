/// Service to detect if a disease is chronic
/// Helps users identify chronic diseases automatically
/// Enhanced with 100+ diseases and better detection
class ChronicDiseaseDetector {
  // Comprehensive list of chronic diseases (100+ conditions)
  static final Set<String> _chronicDiseaseKeywords = {
    // Cardiovascular (Heart & Blood Vessels)
    'hypertension', 'high blood pressure', 'heart disease', 'coronary',
    'cardiac', 'arrhythmia', 'heart failure', 'angina', 'atrial fibrillation',
    'congestive heart failure', 'cardiomyopathy', 'atherosclerosis',
    'peripheral artery disease', 'stroke history', 'heart attack history',

    // Metabolic & Endocrine
    'diabetes', 'diabetic', 'type 1 diabetes', 'type 2 diabetes', 'pre-diabetes',
    'thyroid', 'hyperthyroidism', 'hypothyroidism', 'goiter', 'thyroiditis',
    'metabolic syndrome', 'insulin resistance', 'polycystic ovary', 'pcos',
    'cushings', 'addisons disease', 'hormonal imbalance',

    // Respiratory (Breathing)
    'asthma', 'copd', 'chronic obstructive pulmonary', 'emphysema',
    'bronchitis', 'chronic bronchitis', 'pulmonary fibrosis',
    'sleep apnea', 'chronic cough', 'bronchiectasis',

    // Autoimmune
    'arthritis', 'rheumatoid arthritis', 'lupus', 'psoriasis', 'psoriatic arthritis',
    'crohn', 'crohns disease', 'ulcerative colitis', 'multiple sclerosis', 'ms',
    'sjogren', 'scleroderma', 'polymyalgia', 'vasculitis', 'autoimmune',

    // Neurological (Brain & Nerves)
    'epilepsy', 'seizure', 'seizure disorder', 'parkinson', 'parkinsons',
    'alzheimer', 'dementia', 'migraine', 'chronic headache', 'chronic migraine',
    'neuropathy', 'peripheral neuropathy', 'diabetic neuropathy',
    'huntingtons', 'myasthenia gravis', 'guillain-barre', 'cerebral palsy',

    // Kidney & Urinary
    'kidney disease', 'renal disease', 'chronic kidney disease', 'ckd',
    'kidney failure', 'renal failure', 'nephritis', 'polycystic kidney',
    'nephrotic syndrome', 'glomerulonephritis', 'dialysis',

    // Liver & Digestive
    'hepatitis', 'hepatitis b', 'hepatitis c', 'cirrhosis', 'liver disease',
    'fatty liver', 'chronic liver', 'liver cirrhosis', 'liver failure',
    'ibs', 'irritable bowel syndrome', 'chronic gastritis', 'gastritis',
    'gerd', 'acid reflux', 'celiac', 'celiac disease', 'inflammatory bowel',
    'diverticulitis', 'chronic pancreatitis', 'pancreatic insufficiency',

    // Cancer & Tumors
    'cancer', 'tumor', 'leukemia', 'lymphoma', 'carcinoma', 'sarcoma', 'melanoma',
    'breast cancer', 'lung cancer', 'colon cancer', 'prostate cancer',
    'thyroid cancer', 'liver cancer', 'kidney cancer', 'brain tumor',

    // Mental Health
    'depression', 'major depression', 'clinical depression', 'anxiety disorder',
    'anxiety', 'panic disorder', 'bipolar', 'bipolar disorder', 'schizophrenia',
    'ocd', 'obsessive compulsive', 'ptsd', 'post traumatic stress',
    'chronic stress', 'eating disorder', 'anorexia', 'bulimia',
    'personality disorder', 'borderline personality',

    // Blood Disorders
    'anemia', 'chronic anemia', 'iron deficiency', 'thalassemia', 'hemophilia',
    'sickle cell', 'blood disorder', 'clotting disorder', 'thrombophilia',
    'von willebrand', 'polycythemia',

    // Skin Conditions
    'eczema', 'atopic dermatitis', 'chronic skin', 'psoriasis',
    'vitiligo', 'rosacea', 'chronic urticaria', 'hives',

    // Eye Diseases
    'glaucoma', 'macular degeneration', 'retinopathy', 'diabetic retinopathy',
    'cataracts', 'chronic dry eye', 'uveitis',

    // Bones, Joints & Muscles
    'osteoporosis', 'osteoarthritis', 'fibromyalgia', 'chronic back pain',
    'spinal stenosis', 'herniated disc', 'chronic joint pain',
    'muscular dystrophy', 'osteopenia', 'gout', 'chronic gout',

    // Infectious Diseases (Chronic)
    'hiv', 'aids', 'tuberculosis', 'tb', 'chronic tb', 'leprosy',
    'chronic infection', 'hepatitis b', 'hepatitis c',

    // Women's Health
    'endometriosis', 'pcos', 'polycystic ovary', 'uterine fibroids',
    'chronic pelvic pain', 'menopause symptoms',

    // Men's Health
    'benign prostatic hyperplasia', 'bph', 'prostate enlargement',
    'erectile dysfunction', 'chronic prostatitis',

    // Other Chronic Conditions
    'chronic pain', 'chronic fatigue syndrome', 'cfs', 'fibromyalgia',
    'chronic sinusitis', 'chronic rhinitis', 'chronic allergies',
    'chronic tinnitus', 'chronic vertigo', 'menieres disease',
    'sarcoidosis', 'chronic wounds', 'varicose veins', 'chronic venous',
    'lymphedema', 'chronic swelling',
  };

  /// Check if a disease name indicates it's chronic
  static bool isChronic(String diseaseName) {
    if (diseaseName.isEmpty) return false;

    final lowerDisease = diseaseName.toLowerCase().trim();

    // Check for exact matches or partial matches
    for (final keyword in _chronicDiseaseKeywords) {
      if (lowerDisease.contains(keyword)) {
        return true;
      }
    }

    // Check for "chronic" keyword itself
    if (lowerDisease.contains('chronic')) {
      return true;
    }

    return false;
  }

  /// Detect chronic diseases from a list of diseases
  static List<String> filterChronicDiseases(List<String> diseases) {
    return diseases.where((disease) => isChronic(disease)).toList();
  }

  /// Detect non-chronic (acute) diseases
  static List<String> filterAcuteDiseases(List<String> diseases) {
    return diseases.where((disease) => !isChronic(disease)).toList();
  }

  /// Get a friendly message about chronic disease detection
  static String getDetectionMessage(String diseaseName) {
    if (isChronic(diseaseName)) {
      return '⚠️ This appears to be a chronic disease (long-term condition)';
    } else {
      return 'ℹ️ This appears to be an acute/temporary condition';
    }
  }

  /// Get icon for disease type
  static String getIcon(String diseaseName) {
    if (isChronic(diseaseName)) {
      return '🔴'; // Red dot for chronic
    } else {
      return '🟢'; // Green dot for acute
    }
  }

  /// Get color indicator
  static bool shouldHighlight(String diseaseName) {
    return isChronic(diseaseName);
  }

  /// Analyze a comma-separated string of diseases
  /// Returns a structured analysis result
  static DiseaseAnalysisResult analyzeDiseasesString(String diseasesStr) {
    if (diseasesStr.trim().isEmpty) {
      return DiseaseAnalysisResult(
        totalCount: 0,
        chronicCount: 0,
        acuteCount: 0,
        chronicDiseases: [],
        acuteDiseases: [],
      );
    }

    // Split by comma and clean up
    final diseases = diseasesStr
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();

    final chronic = <String>[];
    final acute = <String>[];

    for (final disease in diseases) {
      if (isChronic(disease)) {
        chronic.add(disease);
      } else {
        acute.add(disease);
      }
    }

    return DiseaseAnalysisResult(
      totalCount: diseases.length,
      chronicCount: chronic.length,
      acuteCount: acute.length,
      chronicDiseases: chronic,
      acuteDiseases: acute,
    );
  }

  /// Get category for a chronic disease
  static String getCategory(String diseaseName) {
    final lower = diseaseName.toLowerCase();

    if (_containsAny(lower, [
      'heart', 'cardiac', 'hypertension', 'blood pressure', 'coronary',
      'arrhythmia', 'angina', 'stroke'
    ])) {
      return 'Cardiovascular';
    } else if (_containsAny(lower, [
      'diabetes', 'thyroid', 'metabolic', 'pcos', 'hormonal'
    ])) {
      return 'Metabolic';
    } else if (_containsAny(lower, [
      'asthma', 'copd', 'respiratory', 'bronchitis', 'emphysema', 'pulmonary'
    ])) {
      return 'Respiratory';
    } else if (_containsAny(lower, [
      'kidney', 'renal', 'nephritis', 'dialysis'
    ])) {
      return 'Kidney';
    } else if (_containsAny(lower, [
      'liver', 'hepatitis', 'cirrhosis'
    ])) {
      return 'Liver';
    } else if (_containsAny(lower, [
      'cancer', 'tumor', 'leukemia', 'lymphoma', 'carcinoma'
    ])) {
      return 'Cancer';
    } else if (_containsAny(lower, [
      'depression', 'anxiety', 'bipolar', 'schizophrenia', 'mental', 'ptsd'
    ])) {
      return 'Mental Health';
    } else if (_containsAny(lower, [
      'arthritis', 'lupus', 'autoimmune', 'multiple sclerosis'
    ])) {
      return 'Autoimmune';
    } else if (_containsAny(lower, [
      'epilepsy', 'parkinson', 'alzheimer', 'neurological', 'dementia'
    ])) {
      return 'Neurological';
    } else if (_containsAny(lower, [
      'bone', 'osteoporosis', 'osteoarthritis', 'joint', 'spine'
    ])) {
      return 'Musculoskeletal';
    } else {
      return 'Other';
    }
  }

  /// Helper method to check if string contains any of the keywords
  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  /// Get a summary message for display
  static String getSummaryMessage(DiseaseAnalysisResult result) {
    if (result.totalCount == 0) {
      return 'No diseases added';
    }

    if (result.chronicCount == 0) {
      return '${result.totalCount} condition(s) - All acute/temporary';
    }

    if (result.acuteCount == 0) {
      return '${result.totalCount} chronic condition(s) detected';
    }

    return '${result.totalCount} condition(s): ${result.chronicCount} chronic, ${result.acuteCount} acute';
  }
}

/// Result of disease analysis
class DiseaseAnalysisResult {
  final int totalCount;
  final int chronicCount;
  final int acuteCount;
  final List<String> chronicDiseases;
  final List<String> acuteDiseases;

  DiseaseAnalysisResult({
    required this.totalCount,
    required this.chronicCount,
    required this.acuteCount,
    required this.chronicDiseases,
    required this.acuteDiseases,
  });

  bool get hasChronicDiseases => chronicCount > 0;
  bool get hasOnlyChronicDiseases => chronicCount > 0 && acuteCount == 0;
  bool get hasOnlyAcuteDiseases => acuteCount > 0 && chronicCount == 0;
}
