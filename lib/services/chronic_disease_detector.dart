/// Service to detect if a disease is chronic
/// Helps users identify chronic diseases automatically
class ChronicDiseaseDetector {
  // Comprehensive list of chronic diseases
  static final Set<String> _chronicDiseaseKeywords = {
    // Cardiovascular
    'hypertension', 'high blood pressure', 'heart disease', 'coronary',
    'cardiac', 'arrhythmia', 'heart failure', 'angina',

    // Metabolic
    'diabetes', 'diabetic', 'type 1 diabetes', 'type 2 diabetes',
    'thyroid', 'hyperthyroidism', 'hypothyroidism', 'goiter',

    // Respiratory
    'asthma', 'copd', 'chronic obstructive pulmonary',
    'bronchitis', 'emphysema',

    // Autoimmune
    'arthritis', 'rheumatoid', 'lupus', 'psoriasis',
    'crohn', 'ulcerative colitis', 'multiple sclerosis',

    // Neurological
    'epilepsy', 'seizure', 'parkinson', 'alzheimer',
    'dementia', 'migraine', 'chronic headache',

    // Kidney/Urinary
    'kidney disease', 'renal', 'chronic kidney',
    'kidney failure', 'nephritis',

    // Liver
    'hepatitis', 'cirrhosis', 'liver disease',
    'fatty liver', 'chronic liver',

    // Cancer
    'cancer', 'tumor', 'leukemia', 'lymphoma',
    'carcinoma', 'sarcoma', 'melanoma',

    // Mental Health
    'depression', 'anxiety', 'bipolar', 'schizophrenia',
    'ocd', 'obsessive compulsive', 'ptsd',

    // Digestive
    'ibs', 'irritable bowel', 'gastritis',
    'gerd', 'acid reflux', 'celiac',

    // Blood
    'anemia', 'thalassemia', 'hemophilia',
    'sickle cell',

    // Skin
    'eczema', 'atopic dermatitis', 'chronic skin',

    // Eyes
    'glaucoma', 'macular degeneration', 'retinopathy',

    // Bones/Joints
    'osteoporosis', 'osteoarthritis', 'fibromyalgia',

    // Other
    'chronic pain', 'chronic fatigue', 'autoimmune',
    'hiv', 'aids', 'hepatitis b', 'hepatitis c',
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
}
