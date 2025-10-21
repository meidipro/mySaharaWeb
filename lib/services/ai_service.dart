import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Enhanced AI Health Companion Service
/// Features:
/// - Bilingual support (Bangla/English)
/// - Symptom analysis
/// - Predictive health intelligence
/// - Health insights & monitoring
/// - Nutrition coaching
/// - Preventive health alerts
class AIService {
  static final String _groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // Conversation history for context
  static final List<Map<String, String>> _conversationHistory = [];

  /// Detect language from message
  static String _detectLanguage(String text) {
    // Check for Bengali Unicode characters (U+0980 to U+09FF)
    final bengaliPattern = RegExp(r'[\u0980-\u09FF]');
    final bengaliMatches = bengaliPattern.allMatches(text).length;
    final totalChars = text.replaceAll(RegExp(r'\s'), '').length;

    if (totalChars > 0 && bengaliMatches / totalChars > 0.2) {
      return 'bn';
    }
    return 'en';
  }

  /// Get enhanced system prompt with bilingual support
  static String _getEnhancedSystemPrompt(String language) {
    if (language == 'bn') {
      return '''আপনি একজন দক্ষ এবং বন্ধুত্বপূর্ণ AI স্বাস্থ্য ডাক্তার (mySahara Health Doctor)। আপনি যেকোনো বিষয়ে সাহায্য করতে পারেন।

আপনার দায়িত্ব:
- রোগীদের সাথে সহানুভূতিশীল এবং উষ্ণভাবে কথা বলুন, যেন একজন বন্ধু বা পারিবারিক ডাক্তার
- স্বাস্থ্য, পুষ্টি, জীবনযাত্রা, মানসিক স্বাস্থ্য - যেকোনো প্রশ্নের উত্তর দিন
- জটিল চিকিৎসা তথ্য সহজ ভাষায় বুঝিয়ে দিন
- বাংলাদেশের প্রেক্ষাপট, স্থানীয় খাবার, আবহাওয়া এবং রোগ সম্পর্কে জ্ঞান রাখুন
- ব্যবহারকারীর আবেগ বুঝুন - উদ্বিগ্ন, অসুস্থ, বা চাপে থাকলে আরও সহায়ক হন
- সাধারণ পরামর্শ দিন কিন্তু গুরুতর সমস্যার জন্য ডাক্তার দেখতে বলুন
- সংক্ষিপ্ত, পরিষ্কার এবং বাস্তব উপযোগী উত্তর দিন (২-৩ অনুচ্ছেদ)

বিশেষ দক্ষতা - ডাক্তার দেখার প্রস্তুতি:
- রোগীদের ডাক্তারের কাছে যাওয়ার আগে প্রস্তুত হতে সাহায্য করুন
- লক্ষণ সংগঠিত করতে, সময়রেখা তৈরি করতে এবং গুরুত্বপূর্ণ বিবরণ মনে রাখতে সহায়তা করুন
- ডাক্তারকে কী জিজ্ঞাসা করতে হবে এবং কীভাবে লক্ষণ বর্ণনা করতে হবে তা শেখান
- রোগীর ব্যক্তিগত স্বাস্থ্য সহায়ক হিসেবে কাজ করুন - যেন ডাক্তারের সাথে দেখা করার আগে একসাথে চিন্তা করছেন
- তাদের উদ্বেগ স্পষ্ট করতে, প্রশ্ন প্রস্তুত করতে এবং আত্মবিশ্বাসের সাথে কথা বলতে সাহায্য করুন

গুরুত্বপূর্ণ নির্দেশনা:
- সবসময় বাংলায় উত্তর দিন যখন প্রশ্ন বাংলায় হয়
- আপনি যেকোনো বিষয়ে প্রশ্নের উত্তর দিতে পারেন - স্বাস্থ্য, সাধারণ জ্ঞান, জীবনযাত্রা, সব কিছু
- কখনও "আমি শুধু স্বাস্থ্য বিষয়ে উত্তর দিতে পারি" বলবেন না
- প্রাকৃতিক এবং কথোপকথনমূলক ভাষা ব্যবহার করুন

দাবিত্যাগ: আমি পেশাদার চিকিৎসা পরামর্শের সম্পূর্ণ বিকল্প নই। গুরুতর সমস্যার জন্য সরাসরি ডাক্তারের পরামর্শ নিন।''';
    } else {
      return '''You are a skilled and friendly AI Health Doctor (mySahara Health Doctor). You can help with any topic.

Your responsibilities:
- Talk to patients with empathy and warmth, like a friend or family doctor
- Answer ANY question - health, nutrition, lifestyle, mental health, general knowledge, anything
- Explain complex medical information in simple, everyday language
- Understand Bangladeshi context (local foods, weather, diseases)
- Detect user's emotion - if they sound anxious, sick, or stressed, be extra supportive
- Give general advice but recommend seeing a doctor for serious issues
- Keep responses concise, clear, and practical (2-3 paragraphs)

Special ability - Preparing patients for doctor visits:
- Help patients prepare before visiting a doctor
- Assist in organizing symptoms, creating timelines, and remembering important details
- Teach them what to ask the doctor and how to describe their symptoms effectively
- Act as the patient's personal health assistant - like thinking together before the doctor visit
- Help them clarify concerns, prepare questions, and speak confidently to their doctor

Important guidelines:
- ALWAYS respond in the SAME language as the user's question
- You can answer questions about ANYTHING - health, general topics, life advice, everything
- NEVER say "I can only answer health questions"
- Use natural, conversational language like a real doctor would
- Be warm, professional, and helpful at all times
- Provide actionable advice that people can actually follow
- Include relevant context for Bangladesh when appropriate

Response style:
- Start with understanding/validation ("I understand your concern...")
- Provide clear, structured information
- End with encouragement or next steps
- Use bullet points for clarity when listing multiple items
- Avoid overly technical jargon unless necessary

Disclaimer: While I provide helpful health information, I'm not a substitute for professional medical advice. Please consult healthcare professionals for serious symptoms or emergencies.''';
    }
  }

  /// Clear conversation history
  static void clearHistory() {
    _conversationHistory.clear();
  }

  /// Enhanced chat with bilingual support and context
  static Future<String> chat(
    String message, {
    bool useHistory = true,
    Map<String, dynamic>? userContext,
  }) async {
    if (_groqApiKey.isEmpty) {
      return _detectLanguage(message) == 'bn'
          ? 'AI সেবা কনফিগার করা হয়নি। দয়া করে .env ফাইলে GROQ_API_KEY যোগ করুন।'
          : 'AI service is not configured. Please add GROQ_API_KEY to your .env file.';
    }

    try {
      print('Sending message to Groq API...');
      print('API Key present: ${_groqApiKey.isNotEmpty}');

      // Detect language
      final language = _detectLanguage(message);
      print('Detected language: $language');

      // Build messages array with context
      final messages = <Map<String, String>>[];

      // Add system prompt
      String systemPrompt = _getEnhancedSystemPrompt(language);

      // Add user context if provided
      if (userContext != null) {
        systemPrompt += '\n\nUser Context:\n';
        if (userContext['age'] != null) {
          systemPrompt += '- Age: ${userContext['age']}\n';
        }
        if (userContext['gender'] != null) {
          systemPrompt += '- Gender: ${userContext['gender']}\n';
        }
        if (userContext['chronicDiseases'] != null &&
            userContext['chronicDiseases'].isNotEmpty) {
          systemPrompt +=
              '- Chronic Conditions: ${userContext['chronicDiseases']}\n';
        }
        if (userContext['location'] != null) {
          systemPrompt += '- Location: ${userContext['location']}\n';
        }
      }

      messages.add({
        'role': 'system',
        'content': systemPrompt,
      });

      // Add conversation history for context
      if (useHistory && _conversationHistory.isNotEmpty) {
        messages.addAll(_conversationHistory.take(10)); // Last 10 messages
      }

      // Add current message
      messages.add({
        'role': 'user',
        'content': message,
      });

      final requestBody = {
        'model': 'llama-3.3-70b-versatile',
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 800,
      };

      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Save to conversation history
        if (useHistory) {
          _conversationHistory.add({
            'role': 'user',
            'content': message,
          });
          _conversationHistory.add({
            'role': 'assistant',
            'content': content.trim(),
          });

          // Keep only last 20 messages (10 exchanges)
          if (_conversationHistory.length > 20) {
            _conversationHistory.removeRange(0, _conversationHistory.length - 20);
          }
        }

        return content.trim();
      } else {
        // Parse error details
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
          print('API Error: $errorMessage');

          if (response.statusCode == 400) {
            return 'Invalid request to AI service. Please check your API key or try again.';
          } else if (response.statusCode == 401) {
            return 'Invalid API key. Please check GROQ_API_KEY in .env file.';
          } else if (response.statusCode == 429) {
            return 'Rate limit exceeded. Please wait a moment and try again.';
          } else {
            return 'AI service error: $errorMessage';
          }
        } catch (e) {
          return 'Failed to get AI response (${response.statusCode}). ${response.body}';
        }
      }
    } catch (e) {
      print('Error in AI chat: $e');
      return 'Sorry, I encountered an error: ${e.toString()}';
    }
  }

  /// Get health recommendations based on symptoms
  static Future<String> getHealthRecommendations(String symptoms) async {
    final prompt = '''
Based on these symptoms: $symptoms

Please provide:
1. Possible causes (general information)
2. Self-care recommendations
3. When to see a doctor

Remember: This is general information only. Always consult a healthcare professional for proper diagnosis.
''';

    return await chat(prompt);
  }

  /// Ask about a specific health condition
  static Future<String> askAboutCondition(String condition) async {
    final prompt = '''
Tell me about the health condition: $condition

Include:
1. What it is
2. Common symptoms
3. General management tips
4. When to seek medical help

Keep it simple and patient-friendly.
''';

    return await chat(prompt);
  }

  // =====================================================
  // 🔹 ENHANCED FEATURES
  // =====================================================

  /// 🔹 Symptom Analysis with Dynamic Follow-up
  static Future<String> analyzeSymptoms({
    required String symptoms,
    String? duration,
    String? severity,
    Map<String, dynamic>? userContext,
  }) async {
    final language = _detectLanguage(symptoms);

    String prompt;
    if (language == 'bn') {
      prompt = '''আমার এই লক্ষণগুলো রয়েছে: $symptoms''';
      if (duration != null) prompt += '\n\nসময়কাল: $duration';
      if (severity != null) prompt += '\nতীব্রতা: $severity';
      prompt += '''

দয়া করে বিশ্লেষণ করুন এবং প্রদান করুন:
১. সম্ভাব্য কারণসমূহ (সাধারণ তথ্য)
২. প্রাথমিক ত্রিয়াজ পরামর্শ (হালকা/মাঝারি/গুরুতর)
৩. স্ব-যত্ন সুপারিশ
৪. কখন ডাক্তার দেখাতে হবে
৫. অতিরিক্ত প্রশ্ন যা নির্ণয়ে সাহায্য করতে পারে

মনে রাখবেন: এটি সাধারণ তথ্য মাত্র। সঠিক রোগ নির্ণয়ের জন্য স্বাস্থ্যসেবা পেশাদারের পরামর্শ নিন।''';
    } else {
      prompt = '''I'm experiencing these symptoms: $symptoms''';
      if (duration != null) prompt += '\n\nDuration: $duration';
      if (severity != null) prompt += '\nSeverity: $severity';
      prompt += '''

Please analyze and provide:
1. Possible causes (general information)
2. Preliminary triage suggestion (mild/moderate/severe)
3. Self-care recommendations
4. When to see a doctor
5. Additional questions that could help narrow down the condition

Remember: This is general information only. Consult a healthcare professional for proper diagnosis.''';
    }

    return await chat(prompt, userContext: userContext);
  }

  /// 🔹 Predictive Health Intelligence
  static Future<String> predictHealthRisks({
    required Map<String, dynamic> healthMetrics,
    List<String>? chronicDiseases,
    Map<String, dynamic>? userContext,
  }) async {
    final language = userContext?['language'] ?? 'en';

    String prompt;
    if (language == 'bn') {
      prompt = '''আমার স্বাস্থ্য তথ্য বিশ্লেষণ করুন:

স্বাস্থ্য মেট্রিক্স:
${healthMetrics.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}''';

      if (chronicDiseases != null && chronicDiseases.isNotEmpty) {
        prompt += '\n\nদীর্ঘস্থায়ী রোগ: ${chronicDiseases.join(", ")}';
      }

      prompt += '''

দয়া করে প্রদান করুন:
১. সম্ভাব্য স্বাস্থ্য ঝুঁকি সনাক্তকরণ
২. প্রাথমিক সতর্ক সংকেত
৩. প্রতিরোধমূলক ব্যবস্থা
৪. জীবনধারা পরিবর্তনের পরামর্শ
৫. কী কী পরীক্ষা করা উচিত (যদি থাকে)

স্বাস্থ্য পূর্বাভাস দিন এবং আমি কীভাবে আমার স্বাস্থ্য উন্নত করতে পারি তা বলুন।''';
    } else {
      prompt = '''Analyze my health data:

Health Metrics:
${healthMetrics.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}''';

      if (chronicDiseases != null && chronicDiseases.isNotEmpty) {
        prompt += '\n\nChronic Conditions: ${chronicDiseases.join(", ")}';
      }

      prompt += '''

Please provide:
1. Potential health risks identification
2. Early warning signs
3. Preventive measures
4. Lifestyle modification recommendations
5. What tests should I consider (if any)

Provide health forecasts and how I can improve my health.''';
    }

    return await chat(prompt, userContext: userContext);
  }

  /// 🔹 Nutrition Coaching (Bangladeshi Food Focus)
  static Future<String> getNutritionAdvice({
    required String goal,
    Map<String, dynamic>? userContext,
    List<String>? dietaryRestrictions,
    String? currentDiet,
  }) async {
    final language = userContext?['language'] ?? 'en';

    String prompt;
    if (language == 'bn') {
      prompt = '''আমার পুষ্টি লক্ষ্য: $goal''';

      if (currentDiet != null) prompt += '\n\nবর্তমান খাদ্যাভ্যাস: $currentDiet';
      if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
        prompt += '\n\nখাদ্য সীমাবদ্ধতা: ${dietaryRestrictions.join(", ")}';
      }

      prompt += '''

বাংলাদেশী স্থানীয় খাবার ব্যবহার করে একটি ব্যক্তিগত পুষ্টি পরিকল্পনা তৈরি করুন:

১. দৈনিক খাদ্য পরিকল্পনা (সকাল, দুপুর, সন্ধ্যা, রাত)
২. স্থানীয় খাবার সুপারিশ (ভাত, ডাল, মাছ, সবজি, ফল)
৩. সাশ্রয়ী মূল্যের খাবার বিকল্প
৪. পুষ্টির ভারসাম্য (প্রোটিন, কার্বোহাইড্রেট, ফ্যাট)
৫. স্বাস্থ্যকর রান্নার পদ্ধতি

মনে রাখবেন বাংলাদেশী রান্নার প্রেক্ষাপট এবং সহজলভ্য উপাদান।''';
    } else {
      prompt = '''My nutrition goal: $goal''';

      if (currentDiet != null) prompt += '\n\nCurrent diet: $currentDiet';
      if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
        prompt += '\n\nDietary restrictions: ${dietaryRestrictions.join(", ")}';
      }

      prompt += '''

Create a personalized nutrition plan using Bangladeshi local foods:

1. Daily meal plan (breakfast, lunch, evening snack, dinner)
2. Local food recommendations (rice, lentils/dal, fish, vegetables, fruits)
3. Affordable food alternatives
4. Nutritional balance (protein, carbs, fats)
5. Healthy cooking methods

Consider Bangladeshi cooking context and easily available ingredients.''';
    }

    return await chat(prompt, userContext: userContext);
  }

  /// 🔹 Daily Health Insights
  static Future<String> getDailyHealthInsights({
    Map<String, dynamic>? userContext,
    Map<String, dynamic>? todayMetrics,
  }) async {
    final language = userContext?['language'] ?? 'en';

    String prompt;
    if (language == 'bn') {
      prompt = '''আজকের স্বাস্থ্য সারাংশ প্রদান করুন।''';

      if (todayMetrics != null && todayMetrics.isNotEmpty) {
        prompt += '\n\nআজকের তথ্য:\n';
        prompt += todayMetrics.entries.map((e) => '- ${e.key}: ${e.value}').join('\n');
      }

      prompt += '''

দয়া করে প্রদান করুন:
১. স্বাস্থ্য অবস্থার মূল্যায়ন
২. আজকের জন্য ব্যক্তিগত স্বাস্থ্য টিপস
৩. হাইড্রেশন অনুস্মারক
৪. শারীরিক কার্যকলাপ পরামর্শ
৫. মানসিক স্বাস্থ্য টিপস (স্ট্রেস ব্যবস্থাপনা)

সংক্ষিপ্ত এবং কার্যকর পরামর্শ দিন।''';
    } else {
      prompt = '''Provide today's health summary.''';

      if (todayMetrics != null && todayMetrics.isNotEmpty) {
        prompt += '\n\nToday\'s metrics:\n';
        prompt += todayMetrics.entries.map((e) => '- ${e.key}: ${e.value}').join('\n');
      }

      prompt += '''

Please provide:
1. Health status assessment
2. Personalized health tips for today
3. Hydration reminders
4. Physical activity suggestions
5. Mental health tips (stress management)

Keep advice brief and actionable.''';
    }

    return await chat(prompt, userContext: userContext);
  }

  /// 🔹 Preventive Health Alerts
  static Future<String> getPreventiveAlerts({
    required String location,
    String? season,
    Map<String, dynamic>? userContext,
  }) async {
    final language = userContext?['language'] ?? 'en';

    // Get current month to determine season if not provided
    final currentMonth = DateTime.now().month;
    season ??= _getSeason(currentMonth);

    String prompt;
    if (language == 'bn') {
      prompt = '''আমার অবস্থান: $location
ঋতু: $season

প্রতিরোধমূলক স্বাস্থ্য সতর্কতা প্রদান করুন:

১. মৌসুমী রোগের ঝুঁকি (ডেঙ্গু, ফ্লু, ইত্যাদি)
২. আবহাওয়া-ভিত্তিক স্বাস্থ্য টিপস
৩. টিকা সময়সূচী অনুস্মারক (যদি প্রাসঙ্গিক হয়)
৪. পরিবেশগত স্বাস্থ্য ঝুঁকি (বায়ু মান, আর্দ্রতা)
৫. প্রতিরোধমূলক ব্যবস্থা

বাংলাদেশের প্রেক্ষাপটে বিশেষ মনোযোগ দিন এবং স্থানীয় স্বাস্থ্য চ্যালেঞ্জ বিবেচনা করুন।''';
    } else {
      prompt = '''My location: $location
Season: $season

Provide preventive health alerts:

1. Seasonal disease risks (dengue, flu, etc.)
2. Weather-based health tips
3. Vaccination schedule reminders (if relevant)
4. Environmental health risks (air quality, humidity)
5. Preventive measures

Focus on Bangladesh context and consider local health challenges.''';
    }

    return await chat(prompt, userContext: userContext, useHistory: false);
  }

  /// 🔹 Vaccination Reminders
  static Future<String> getVaccinationSchedule({
    int? age,
    List<String>? completedVaccines,
    Map<String, dynamic>? userContext,
  }) async {
    final language = userContext?['language'] ?? 'en';

    String prompt;
    if (language == 'bn') {
      prompt = '''টিকা সময়সূচী তথ্য প্রদান করুন''';
      if (age != null) prompt += '\n\nবয়স: $age বছর';
      if (completedVaccines != null && completedVaccines.isNotEmpty) {
        prompt += '\n\nসম্পন্ন টিকা: ${completedVaccines.join(", ")}';
      }

      prompt += '''

দয়া করে প্রদান করুন:
১. প্রয়োজনীয় টিকার তালিকা
২. আসন্ন টিকার সময়সূচী
৩. বাংলাদেশে কোথায় টিকা পাওয়া যায়
৪. টিকার গুরুত্ব এবং সুবিধা

বাংলাদেশের জাতীয় টিকাদান কর্মসূচি বিবেচনা করুন।''';
    } else {
      prompt = '''Provide vaccination schedule information''';
      if (age != null) prompt += '\n\nAge: $age years';
      if (completedVaccines != null && completedVaccines.isNotEmpty) {
        prompt += '\n\nCompleted vaccines: ${completedVaccines.join(", ")}';
      }

      prompt += '''

Please provide:
1. Required vaccine list
2. Upcoming vaccination schedule
3. Where to get vaccines in Bangladesh
4. Importance and benefits of vaccines

Consider Bangladesh's national immunization program (EPI).''';
    }

    return await chat(prompt, userContext: userContext, useHistory: false);
  }

  /// Get season from month
  static String _getSeason(int month) {
    if (month >= 3 && month <= 5) return 'Spring/Pre-Monsoon (গ্রীষ্ম)';
    if (month >= 6 && month <= 9) return 'Monsoon/Rainy (বর্ষা)';
    if (month >= 10 && month <= 11) return 'Autumn (শরৎ)';
    return 'Winter (শীত)';
  }

  /// 🔹 Lifestyle & Sleep Optimization
  static Future<String> getLifestyleAdvice({
    required String focusArea, // 'sleep', 'stress', 'exercise', 'hydration'
    Map<String, dynamic>? currentHabits,
    Map<String, dynamic>? userContext,
  }) async {
    final language = userContext?['language'] ?? 'en';

    String prompt;
    if (language == 'bn') {
      final focusAreaBn = {
        'sleep': 'ঘুম',
        'stress': 'মানসিক চাপ',
        'exercise': 'ব্যায়াম',
        'hydration': 'পানি পান',
      };

      prompt = '''${focusAreaBn[focusArea] ?? focusArea} উন্নতির জন্য পরামর্শ চাই।''';

      if (currentHabits != null && currentHabits.isNotEmpty) {
        prompt += '\n\nবর্তমান অভ্যাস:\n';
        prompt += currentHabits.entries.map((e) => '- ${e.key}: ${e.value}').join('\n');
      }

      prompt += '''

দয়া করে প্রদান করুন:
১. ব্যক্তিগত উন্নতির পরামর্শ
২. বাস্তবসম্মত লক্ষ্য নির্ধারণ
৩. দৈনিক রুটিন পরিকল্পনা
৪. সাধারণ চ্যালেঞ্জ এবং সমাধান
৫. অগ্রগতি ট্র্যাক করার উপায়

বাংলাদেশী জীবনযাত্রার প্রেক্ষাপট বিবেচনা করুন।''';
    } else {
      prompt = '''I want advice for improving: $focusArea.''';

      if (currentHabits != null && currentHabits.isNotEmpty) {
        prompt += '\n\nCurrent habits:\n';
        prompt += currentHabits.entries.map((e) => '- ${e.key}: ${e.value}').join('\n');
      }

      prompt += '''

Please provide:
1. Personalized improvement recommendations
2. Realistic goal setting
3. Daily routine planning
4. Common challenges and solutions
5. Ways to track progress

Consider Bangladeshi lifestyle context.''';
    }

    return await chat(prompt, userContext: userContext);
  }
}
