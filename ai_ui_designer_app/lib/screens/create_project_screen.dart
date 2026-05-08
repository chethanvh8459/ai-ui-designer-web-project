import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:ai_ui_designer_app/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController promptController = TextEditingController();

  late stt.SpeechToText _speech;
  bool isListening = false;
  bool isGenerating = false; // 🔥 Added a loading state

  File? selectedImage; 

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // 🎤 VOICE
  void _toggleListening() async {
    if (!isListening) {
      bool available = await _speech.initialize();

      if (available) {
        setState(() => isListening = true);

        _speech.listen(
          onResult: (result) {
            setState(() {
              promptController.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => isListening = false);
      _speech.stop();
    }
  }

  // 📷 IMAGE PICKER
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.createProject),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView( // Added scroll view to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔹 PROJECT NAME
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: t.projectName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 TITLE
              Text(
                t.describeUI,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // 🔥 PROMPT BOX
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [

                    // ✏️ TEXT INPUT
                    TextField(
                      controller: promptController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "${t.describeUI}...\n${t.projectName}",
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔥 IMAGE PREVIEW
                    if (selectedImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          selectedImage!,
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // 🔥 ACTION ROW (IMAGE + MIC)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          // 📷 IMAGE BUTTON
                          GestureDetector(
                            onTap: pickImage,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey.shade300,
                              child: const Icon(
                                Icons.image,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // 🎤 MIC BUTTON
                          GestureDetector(
                            onTap: _toggleListening,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  isListening ? Colors.red : Colors.blue,
                              child: Icon(
                                isListening ? Icons.mic : Icons.mic_none,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🔥 GENERATE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isGenerating ? null : () async {
                    String name = nameController.text.trim();
                    String prompt = promptController.text.trim();

                    if (name.isEmpty || prompt.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.fillFields)),
                      );
                      return;
                    }

                    // 1. Show loading state
                    setState(() {
                      isGenerating = true;
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("AI is designing your UI... Please wait ⏳")),
                    );

                    try {
                      // 2. Get the logged-in user's email
                      final prefs = await SharedPreferences.getInstance();
                      String userEmail = prefs.getString("userEmail") ?? "anonymous";

                      // 3. Send to Node.js Backend
                      final response = await http.post(
                        Uri.parse('https://internship-backend-api.vercel.app/api/design/generate'),
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({
                          "email": userEmail,
                          "projectName": name,
                          "prompt": prompt
                        }),
                      );

                      var data = jsonDecode(response.body);

                      if (response.statusCode == 200) {
                        // Success! The code is in data['code']
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ UI Generated and Saved to Database!")),
                        );
                        
                        // You can print it to the console to verify
                        print("GENERATED CODE:\n" + data['code']);
                        
                        Navigator.pop(context); // Go back to dashboard
                      } else {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: ${data['message']}")),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Server error. Is Node.js running?")),
                      );
                    } finally {
                      if (context.mounted) {
                        setState(() {
                          isGenerating = false;
                        });
                      }
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: isGenerating 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text(
                          t.generateUI,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}