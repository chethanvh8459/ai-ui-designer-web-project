import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:ai_ui_designer_app/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CreateProjectScreen extends StatefulWidget {
  final Map<String, dynamic>? templateData;
  
  const CreateProjectScreen({super.key, this.templateData});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController promptController = TextEditingController();

  late stt.SpeechToText _speech;
  bool isListening = false;
  bool isGenerating = false;

  File? selectedImage; 

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadTemplateData();
  }
  
  void _loadTemplateData() {
    if (widget.templateData != null) {
      final template = widget.templateData!;
      
      String projectName = template['title'] ?? 'Template Project';
      if (!projectName.endsWith(' App') && !projectName.endsWith(' app')) {
        projectName = '$projectName App';
      }
      nameController.text = projectName;
      
      if (template['prompt'] != null) {
        promptController.text = template['prompt'];
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${template['title']} template loaded! You can modify the prompt before generating.'),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

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
  void dispose() {
    nameController.dispose();
    promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.createProject),
        actions: widget.templateData != null ? [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (widget.templateData!['color'] as Color?) ?? Colors.purple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.style, color: Colors.white, size: 16), // Changed from Icons.template
                const SizedBox(width: 4),
                Text(
                  widget.templateData!['title'] ?? 'Template',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ] : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: t.projectName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: widget.templateData != null ? 'E.g., My E-Commerce App' : null,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                t.describeUI,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

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

                    TextField(
                      controller: promptController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.templateData != null 
                            ? "Modify the template prompt or add more details...\n\nExample: Add dark mode, responsive design, etc."
                            : "${t.describeUI}...\n${t.projectName}",
                      ),
                    ),

                    const SizedBox(height: 10),

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

                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

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

              if (widget.templateData != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (widget.templateData!['color'] as Color?)?.withOpacity(0.1) ?? Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (widget.templateData!['color'] as Color?) ?? Colors.purple,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: widget.templateData!['color'] as Color? ?? Colors.purple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This is a pre-designed template. You can customize the prompt above to add your specific requirements.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

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

                    setState(() {
                      isGenerating = true;
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("AI is designing your UI... Please wait ⏳")),
                    );

                    try {
                      final prefs = await SharedPreferences.getInstance();
                      String userEmail = prefs.getString("userEmail") ?? "anonymous";

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
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ UI Generated and Saved to Database!")),
                        );
                        
                        print("GENERATED CODE:\n" + data['code']);
                        
                        Navigator.pop(context, true);
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
                    backgroundColor: widget.templateData != null 
                        ? (widget.templateData!['color'] as Color?) ?? const Color(0xFF1A1A2E)
                        : const Color(0xFF1A1A2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: isGenerating 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text(
                          widget.templateData != null 
                              ? 'Generate ${widget.templateData!['title']} App'
                              : t.generateUI,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}