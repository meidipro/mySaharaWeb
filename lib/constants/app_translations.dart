/// Comprehensive translations for English and Bengali
class AppTranslations {
  static const Map<String, Map<String, String>> _translations = {
    // Common
    'app_name': {'en': 'mySahara', 'bn': 'মাইসাহারা'},
    'welcome': {'en': 'Welcome', 'bn': 'স্বাগতম'},
    'save': {'en': 'Save', 'bn': 'সংরক্ষণ করুন'},
    'cancel': {'en': 'Cancel', 'bn': 'বাতিল'},
    'delete': {'en': 'Delete', 'bn': 'মুছুন'},
    'edit': {'en': 'Edit', 'bn': 'সম্পাদনা'},
    'add': {'en': 'Add', 'bn': 'যোগ করুন'},
    'close': {'en': 'Close', 'bn': 'বন্ধ করুন'},
    'yes': {'en': 'Yes', 'bn': 'হ্যাঁ'},
    'no': {'en': 'No', 'bn': 'না'},
    'loading': {'en': 'Loading...', 'bn': 'লোড হচ্ছে...'},
    'error': {'en': 'Error', 'bn': 'ত্রুটি'},
    'success': {'en': 'Success', 'bn': 'সফল'},
    'search': {'en': 'Search', 'bn': 'খুঁজুন'},
    'optional': {'en': 'Optional', 'bn': 'ঐচ্ছিক'},

    // Auth
    'login': {'en': 'Login', 'bn': 'লগইন'},
    'sign_up': {'en': 'Sign Up', 'bn': 'নিবন্ধন'},
    'logout': {'en': 'Logout', 'bn': 'লগআউট'},
    'email': {'en': 'Email', 'bn': 'ইমেইল'},
    'password': {'en': 'Password', 'bn': 'পাসওয়ার্ড'},
    'full_name': {'en': 'Full Name', 'bn': 'পুরো নাম'},
    'forgot_password': {'en': 'Forgot Password?', 'bn': 'পাসওয়ার্ড ভুলে গেছেন?'},

    // Navigation
    'home': {'en': 'Home', 'bn': 'হোম'},
    'records': {'en': 'Records', 'bn': 'রেকর্ড'},
    'timeline': {'en': 'Timeline', 'bn': 'টাইমলাইন'},
    'medical_history': {'en': 'Medi History', 'bn': 'ইতিহাস'},
    'family': {'en': 'Family', 'bn': 'পরিবার'},
    'ai_assistant': {'en': 'AI Assistant', 'bn': 'এআই সহায়ক'},
    'ai_nutrition_fitness': {'en': 'AI Coach', 'bn': 'এআই কোচ'},
    'personalized_plans': {'en': 'Personalized plans', 'bn': 'ব্যক্তিগত পরিকল্পনা'},

    // Home Screen
    'welcome_back': {'en': 'Welcome back,', 'bn': 'ফিরে আসার জন্য স্বাগতম,'},
    'documents': {'en': 'Documents', 'bn': 'নথি'},
    'medications': {'en': 'Medications', 'bn': 'ওষুধ'},
    'appointments': {'en': 'Appointments', 'bn': 'অ্যাপয়েন্টমেন্ট'},
    'quick_actions': {'en': 'Quick Actions', 'bn': 'দ্রুত কাজ'},
    'scan_document': {'en': 'Scan Document', 'bn': 'নথি স্ক্যান'},
    'scan_qr': {'en': 'Scan QR', 'bn': 'QR স্ক্যান'},
    'share_history': {'en': 'Share History', 'bn': 'ইতিহাস শেয়ার'},
    'upload_file': {'en': 'Upload File', 'bn': 'ফাইল আপলোড'},
    'recent_documents': {'en': 'Recent Documents', 'bn': 'সাম্প্রতিক নথি'},
    'view_all': {'en': 'View All', 'bn': 'সব দেখুন'},
    'no_documents_yet': {'en': 'No documents yet', 'bn': 'এখনও কোন নথি নেই'},
    'health_tip': {'en': 'Health Tip', 'bn': 'স্বাস্থ্য টিপস'},
    'health_metrics': {'en': 'Health Metrics', 'bn': 'স্বাস্থ্য মেট্রিক্স'},
    'bmi': {'en': 'BMI', 'bn': 'বিএমআই'},
    'bmr': {'en': 'BMR', 'bn': 'বিএমআর'},
    'track_health_metrics': {'en': 'Track Your Health Metrics', 'bn': 'আপনার স্বাস্থ্য মেট্রিক্স ট্র্যাক করুন'},
    'add_height_weight': {'en': 'Add your height and weight to see your BMI & BMR', 'bn': 'আপনার বিএমআই এবং বিএমআর দেখতে আপনার উচ্চতা এবং ওজন যোগ করুন'},

    // Health Records
    'health_records': {'en': 'Health Records', 'bn': 'স্বাস্থ্য রেকর্ড'},
    'add_record': {'en': 'Add Record', 'bn': 'রেকর্ড যোগ করুন'},
    'add_health_record': {'en': 'Add Health Record', 'bn': 'স্বাস্থ্য রেকর্ড যোগ করুন'},
    'document_title': {'en': 'Document Title', 'bn': 'নথির শিরোনাম'},
    'document_type': {'en': 'Document Type', 'bn': 'নথির ধরন'},
    'description': {'en': 'Description', 'bn': 'বিবরণ'},
    'disease': {'en': 'Disease', 'bn': 'রোগ'},
    'doctor_name': {'en': 'Doctor Name', 'bn': 'ডাক্তারের নাম'},
    'hospital': {'en': 'Hospital', 'bn': 'হাসপাতাল'},
    'document_date': {'en': 'Document Date', 'bn': 'নথির তারিখ'},
    'select_file': {'en': 'Select File', 'bn': 'ফাইল নির্বাচন করুন'},
    'no_file_selected': {'en': 'No file selected', 'bn': 'কোন ফাইল নির্বাচিত হয়নি'},

    // Document Types
    'prescription': {'en': 'Prescription', 'bn': 'প্রেসক্রিপশন'},
    'lab_report': {'en': 'Lab Report', 'bn': 'ল্যাব রিপোর্ট'},
    'xray': {'en': 'X-Ray', 'bn': 'এক্স-রে'},
    'mri': {'en': 'MRI', 'bn': 'এমআরআই'},
    'ct_scan': {'en': 'CT Scan', 'bn': 'সিটি স্ক্যান'},
    'ultrasound': {'en': 'Ultrasound', 'bn': 'আল্ট্রাসাউন্ড'},
    'vaccination': {'en': 'Vaccination', 'bn': 'টিকা'},
    'other': {'en': 'Other', 'bn': 'অন্যান্য'},

    // Medical Timeline
    'medical_timeline': {'en': 'Medical Timeline', 'bn': 'চিকিৎসা টাইমলাইন'},
    'add_event': {'en': 'Add Event', 'bn': 'ইভেন্ট যোগ করুন'},
    'add_medical_event': {'en': 'Add Medical Event', 'bn': 'চিকিৎসা ইভেন্ট যোগ করুন'},
    'add_medical_history': {'en': 'Add Medical History', 'bn': 'চিকিৎসা ইতিহাস যোগ করুন'},
    'event_type': {'en': 'Event Type', 'bn': 'ইভেন্টের ধরন'},
    'event_date': {'en': 'Event Date', 'bn': 'ইভেন্টের তারিখ'},
    'symptoms': {'en': 'Symptoms', 'bn': 'লক্ষণ'},
    'treatment': {'en': 'Treatment', 'bn': 'চিকিৎসা'},
    'notes': {'en': 'Notes', 'bn': 'নোট'},
    'no_events_yet': {'en': 'No medical events yet', 'bn': 'এখনও কোন চিকিৎসা ইভেন্ট নেই'},
    'attach_documents': {'en': 'Attach Documents', 'bn': 'নথি সংযুক্ত করুন'},
    'select_existing_records': {'en': 'Select Existing Records', 'bn': 'বিদ্যমান রেকর্ড নির্বাচন করুন'},
    'upload_new_document': {'en': 'Upload New Document', 'bn': 'নতুন নথি আপলোড করুন'},
    'attached_documents': {'en': 'Attached Documents', 'bn': 'সংযুক্ত নথি'},
    'no_documents_attached': {'en': 'No documents attached', 'bn': 'কোন নথি সংযুক্ত নেই'},
    'documents_count': {'en': 'documents', 'bn': 'নথি'},

    // Event Types
    'diagnosis': {'en': 'Diagnosis', 'bn': 'রোগ নির্ণয়'},
    'surgery': {'en': 'Surgery', 'bn': 'অস্ত্রোপচার'},
    'consultation': {'en': 'Consultation', 'bn': 'পরামর্শ'},
    'emergency': {'en': 'Emergency', 'bn': 'জরুরি'},
    'checkup': {'en': 'Checkup', 'bn': 'চেকআপ'},

    // Family
    'family_health': {'en': 'Family Health', 'bn': 'পারিবারিক স্বাস্থ্য'},
    'family_members': {'en': 'Family Members', 'bn': 'পরিবারের সদস্য'},
    'add_member': {'en': 'Add Member', 'bn': 'সদস্য যোগ করুন'},
    'add_family_member': {'en': 'Add Family Member', 'bn': 'পরিবারের সদস্য যোগ করুন'},
    'generate_invite_code': {'en': 'Generate Invite Code', 'bn': 'আমন্ত্রণ কোড তৈরি করুন'},
    'enter_invite_code': {'en': 'Enter Invite Code', 'bn': 'আমন্ত্রণ কোড লিখুন'},
    'relationship': {'en': 'Relationship', 'bn': 'সম্পর্ক'},
    'date_of_birth': {'en': 'Date of Birth', 'bn': 'জন্ম তারিখ'},
    'gender': {'en': 'Gender', 'bn': 'লিঙ্গ'},
    'blood_group': {'en': 'Blood Group', 'bn': 'রক্তের গ্রুপ'},
    'chronic_diseases': {'en': 'Chronic Diseases', 'bn': 'দীর্ঘস্থায়ী রোগ'},
    'allergies': {'en': 'Allergies', 'bn': 'অ্যালার্জি'},
    'total_members': {'en': 'Total Members', 'bn': 'মোট সদস্য'},
    'on_medication': {'en': 'On Medication', 'bn': 'ওষুধে আছে'},
    'no_family_members': {'en': 'No family members yet', 'bn': 'এখনও কোন পরিবারের সদস্য নেই'},
    'linked': {'en': 'Linked', 'bn': 'সংযুক্ত'},
    'not_connected': {'en': 'Not Connected to App', 'bn': 'অ্যাপে সংযুক্ত নয়'},
    'recent_conditions': {'en': 'Recent Conditions', 'bn': 'সাম্প্রতিক অবস্থা'},

    // Relationships
    'father': {'en': 'Father', 'bn': 'বাবা'},
    'mother': {'en': 'Mother', 'bn': 'মা'},
    'brother': {'en': 'Brother', 'bn': 'ভাই'},
    'sister': {'en': 'Sister', 'bn': 'বোন'},
    'son': {'en': 'Son', 'bn': 'ছেলে'},
    'daughter': {'en': 'Daughter', 'bn': 'মেয়ে'},
    'spouse': {'en': 'Spouse', 'bn': 'স্বামী/স্ত্রী'},
    'grandfather': {'en': 'Grandfather', 'bn': 'দাদা/নানা'},
    'grandmother': {'en': 'Grandmother', 'bn': 'দাদি/নানি'},

    // Genders
    'male': {'en': 'Male', 'bn': 'পুরুষ'},
    'female': {'en': 'Female', 'bn': 'মহিলা'},

    // Invite System
    'invite_code': {'en': 'Invite Code', 'bn': 'আমন্ত্রণ কোড'},
    'share_code': {'en': 'Share this code with your family member:', 'bn': 'আপনার পরিবারের সদস্যের সাথে এই কোড শেয়ার করুন:'},
    'expires': {'en': 'Expires', 'bn': 'মেয়াদ শেষ'},
    'copy_code': {'en': 'Copy Code', 'bn': 'কোড কপি করুন'},
    'copied': {'en': 'Copied', 'bn': 'কপি হয়েছে'},
    'connect': {'en': 'Connect', 'bn': 'সংযুক্ত করুন'},
    'generate': {'en': 'Generate', 'bn': 'তৈরি করুন'},
    'enter_code': {'en': 'Enter the 6-digit code shared by your family member:', 'bn': 'আপনার পরিবারের সদস্যের দেওয়া ৬ ডিজিটের কোড লিখুন:'},

    // Settings
    'settings': {'en': 'Settings', 'bn': 'সেটিংস'},
    'profile': {'en': 'Profile', 'bn': 'প্রোফাইল'},
    'language': {'en': 'Language', 'bn': 'ভাষা'},
    'select_language': {'en': 'Select Language', 'bn': 'ভাষা নির্বাচন করুন'},
    'notifications': {'en': 'Notifications', 'bn': 'বিজ্ঞপ্তি'},
    'privacy': {'en': 'Privacy', 'bn': 'গোপনীয়তা'},
    'about': {'en': 'About', 'bn': 'সম্পর্কে'},
    'help': {'en': 'Help', 'bn': 'সাহায্য'},
    'profile_preferences': {'en': 'Profile & Preferences', 'bn': 'প্রোফাইল এবং পছন্দসমূহ'},
    'security': {'en': 'Security', 'bn': 'নিরাপত্তা'},
    'preferences': {'en': 'Preferences', 'bn': 'পছন্দসমূহ'},
    'edit_profile': {'en': 'Edit Profile', 'bn': 'প্রোফাইল সম্পাদনা'},
    'update_personal_info': {'en': 'Update your personal information', 'bn': 'আপনার ব্যক্তিগত তথ্য আপডেট করুন'},
    'health_calculator': {'en': 'Health Calculator', 'bn': 'স্বাস্থ্য ক্যালকুলেটর'},
    'bmi_calculator': {'en': 'BMI & Health Metrics', 'bn': 'বিএমআই এবং স্বাস্থ্য মেট্রিক্স'},
    'change_password': {'en': 'Change Password', 'bn': 'পাসওয়ার্ড পরিবর্তন'},
    'update_password': {'en': 'Update your account password', 'bn': 'আপনার অ্যাকাউন্টের পাসওয়ার্ড আপডেট করুন'},
    'about_app': {'en': 'About App', 'bn': 'অ্যাপ সম্পর্কে'},
    'version': {'en': 'Version', 'bn': 'সংস্করণ'},
    'help_support': {'en': 'Help & Support', 'bn': 'সাহায্য এবং সহায়তা'},
    'contact_us': {'en': 'Contact us for assistance', 'bn': 'সহায়তার জন্য আমাদের সাথে যোগাযোগ করুন'},
    'privacy_policy': {'en': 'Privacy Policy', 'bn': 'গোপনীয়তা নীতি'},
    'data_protection': {'en': 'Data protection & security', 'bn': 'ডেটা সুরক্ষা এবং নিরাপত্তা'},
    'logout_confirm': {'en': 'Are you sure you want to logout?', 'bn': 'আপনি কি নিশ্চিত যে আপনি লগআউট করতে চান?'},
    'ok': {'en': 'OK', 'bn': 'ঠিক আছে'},
    'user': {'en': 'User', 'bn': 'ব্যবহারকারী'},
    'about_description': {'en': 'mySahara is a comprehensive health record management app that helps you track your medical history, communicate with doctors, and get AI-powered health insights.', 'bn': 'মাইসাহারা একটি ব্যাপক স্বাস্থ্য রেকর্ড ব্যবস্থাপনা অ্যাপ যা আপনাকে আপনার চিকিৎসা ইতিহাস ট্র্যাক করতে, ডাক্তারদের সাথে যোগাযোগ করতে এবং এআই-চালিত স্বাস্থ্য অন্তর্দৃষ্টি পেতে সাহায্য করে।'},
    'help_description': {'en': 'For support and assistance, please contact us at:\n\nEmail: support@mysahara.com\nPhone: +880-XXX-XXXXXX', 'bn': 'সহায়তা এবং সহায়তার জন্য, অনুগ্রহ করে আমাদের সাথে যোগাযোগ করুন:\n\nইমেইল: support@mysahara.com\nফোন: +880-XXX-XXXXXX'},
    'privacy_description': {'en': 'We are committed to protecting your privacy and personal health information. Your data is encrypted and stored securely. We do not share your personal information with third parties without your consent.', 'bn': 'আমরা আপনার গোপনীয়তা এবং ব্যক্তিগত স্বাস্থ্য তথ্য রক্ষা করতে প্রতিশ্রুতিবদ্ধ। আপনার ডেটা এনক্রিপ্ট করা এবং নিরাপদভাবে সংরক্ষিত। আমরা আপনার সম্মতি ছাড়া তৃতীয় পক্ষের সাথে আপনার ব্যক্তিগত তথ্য শেয়ার করি না।'},

    // Messages
    'delete_confirmation': {'en': 'Are you sure you want to delete?', 'bn': 'আপনি কি নিশ্চিত যে আপনি মুছে ফেলতে চান?'},
    'cannot_undo': {'en': 'This action cannot be undone.', 'bn': 'এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।'},
    'deleted_successfully': {'en': 'Deleted successfully', 'bn': 'সফলভাবে মুছে ফেলা হয়েছে'},
    'saved_successfully': {'en': 'Saved successfully', 'bn': 'সফলভাবে সংরক্ষিত হয়েছে'},
    'updated_successfully': {'en': 'Updated successfully', 'bn': 'সফলভাবে আপডেট হয়েছে'},
    'added_successfully': {'en': 'Added successfully', 'bn': 'সফলভাবে যোগ করা হয়েছে'},
    'failed': {'en': 'Failed', 'bn': 'ব্যর্থ'},
    'try_again': {'en': 'Please try again', 'bn': 'অনুগ্রহ করে আবার চেষ্টা করুন'},
    'invalid_code': {'en': 'Invalid or expired code', 'bn': 'অবৈধ বা মেয়াদোত্তীর্ণ কোড'},
    'connection_successful': {'en': 'Family member connected successfully!', 'bn': 'পরিবারের সদস্য সফলভাবে সংযুক্ত হয়েছে!'},

    // Health Summary
    'health_summary': {'en': 'Health Summary', 'bn': 'স্বাস্থ্য সারাংশ'},
    'family_health_overview': {'en': 'Family Health Overview', 'bn': 'পারিবারিক স্বাস্থ্য সংক্ষিপ্ত বিবরণ'},
    'medical_documents': {'en': 'Medical Documents', 'bn': 'চিকিৎসা নথি'},
    'timeline_events': {'en': 'Timeline Events', 'bn': 'টাইমলাইন ইভেন্ট'},
    'account_status': {'en': 'Account Status', 'bn': 'অ্যাকাউন্ট স্ট্যাটাস'},
    'connected_to_app': {'en': 'Connected to App Account', 'bn': 'অ্যাপ অ্যাকাউন্টে সংযুক্ত'},
    'view_health_summary': {'en': 'This family member has their own account and you can view their health summary', 'bn': 'এই পরিবারের সদস্যের নিজস্ব অ্যাকাউন্ট আছে এবং আপনি তাদের স্বাস্থ্য সারাংশ দেখতে পারেন'},
    'no_account_yet': {'en': 'This family member does not have an app account yet', 'bn': 'এই পরিবারের সদস্যের এখনও অ্যাপ অ্যাকাউন্ট নেই'},

    // AI Assistant
    'ai_chat': {'en': 'AI Health Assistant', 'bn': 'এআই স্বাস্থ্য সহায়ক'},
    'ask_anything': {'en': 'Ask me anything about your health...', 'bn': 'আপনার স্বাস্থ্য সম্পর্কে আমাকে কিছু জিজ্ঞাসা করুন...'},
    'send': {'en': 'Send', 'bn': 'পাঠান'},

    // AI Nutrition & Fitness
    'ai_coach_progress': {'en': 'AI Coach & Progress', 'bn': 'এআই কোচ ও অগ্রগতি'},
    'meal_plan': {'en': 'Meal Plan', 'bn': 'মিল প্ল্যান'},
    'recipes': {'en': 'Recipes', 'bn': 'রেসিপি'},
    'insights': {'en': 'Insights', 'bn': 'ইনসাইটস'},
    'workouts': {'en': 'Workouts', 'bn': 'ওয়ার্কআউট'},
    'progress': {'en': 'Progress', 'bn': 'অগ্রগতি'},
    'generate_ai_plan': {'en': 'Generate Your AI Plan', 'bn': 'আপনার এআই প্ল্যান তৈরি করুন'},
    'log_daily_metrics': {'en': 'Log Your Daily Metrics', 'bn': 'দৈনিক মেট্রিক্স সংরক্ষণ করুন'},
    'save_todays_log': {'en': "Save Today's Log", 'bn': 'আজকের লগ সংরক্ষণ করুন'},

    // Validation
    'required_field': {'en': 'This field is required', 'bn': 'এই ক্ষেত্রটি প্রয়োজনীয়'},
    'invalid_email': {'en': 'Invalid email address', 'bn': 'অবৈধ ইমেইল ঠিকানা'},
    'password_too_short': {'en': 'Password must be at least 6 characters', 'bn': 'পাসওয়ার্ড কমপক্ষে ৬ টি অক্ষর হতে হবে'},
  };

  /// Get translation for a key in the specified language
  static String get(String key, String languageCode) {
    final translations = _translations[key];
    if (translations == null) return key;
    return translations[languageCode] ?? translations['en'] ?? key;
  }

  /// Check if a translation exists
  static bool has(String key) {
    return _translations.containsKey(key);
  }
}
