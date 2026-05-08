import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ai_ui_designer_app/l10n/app_localizations.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String username = "";
  String email = "";
  String userLevel = "";
  String userRole = "";
  int projectCount = 0;
  int designCount = 0;
  int savedCount = 0;

  File? _image;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Color primaryColor = const Color(0xFF6366F1);
  final Color secondaryColor = const Color(0xFF8B5CF6);
  final Color accentColor = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadStats();
    setupAnimations();
  }

  void setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString("profile_image");

    File? tempImage;
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (await file.exists()) {
        tempImage = file;
      }
    }

    if (!mounted) return;

    setState(() {
      username =
          prefs.getString("userName") ??
          prefs.getString("username") ??
          "Designer";
      email =
          prefs.getString("userEmail") ??
          prefs.getString("email") ??
          "designer@example.com";
      userLevel = prefs.getString("userLevel") ?? "Beginner";
      userRole = prefs.getString("userRole") ?? "UI Designer";
      _image = tempImage;
    });
  }

  Future<void> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      projectCount = prefs.getInt("projectCount") ?? 12;
      designCount = prefs.getInt("designCount") ?? 34;
      savedCount = prefs.getInt("savedCount") ?? 8;
    });
  }

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final newPath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
    final savedImage = await File(picked.path).copy(newPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("profile_image", savedImage.path);
    await loadUserData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile picture updated!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showUsernameDialog() {
    final controller = TextEditingController(text: username);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Change Username"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter new username",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString("userName", newName);
              await prefs.setString("username", newName);

              if (!mounted) return;
              setState(() => username = newName);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Username updated!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // Professional App Bar with Gradient
                SliverAppBar(
                  expandedHeight: 280,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor,
                            secondaryColor,
                            const Color(0xFFA855F7),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            // Profile Image with Shadow
                            GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.3,
                                  ),
                                  child: ClipOval(
                                    child: _image != null
                                        ? Image.file(
                                            _image!,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.error,
                                                  color: Colors.white,
                                                  size: 50,
                                                ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 60,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: accentColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    userRole,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: _showUsernameDialog,
                    ),
                  ],
                ),

                // Content Section
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),

                          // Stats Cards
                          _buildStatsRow(),
                          const SizedBox(height: 24),

                          // Personal Information Card
                          _buildInfoCard(),
                          const SizedBox(height: 20),

                          // Settings Section
                          _buildSettingsSection(),
                          const SizedBox(height: 20),

                          // Logout Button
                          _buildLogoutButton(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      {
        'icon': Icons.folder_outlined,
        'label': 'Projects',
        'value': projectCount.toString(),
        'color': primaryColor,
      },
      {
        'icon': Icons.design_services,
        'label': 'Designs',
        'value': designCount.toString(),
        'color': accentColor,
      },
      {
        'icon': Icons.bookmark_outline,
        'label': 'Saved',
        'value': savedCount.toString(),
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + (stats.indexOf(stat) * 100)),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (stat['color'] as Color).withOpacity(0.1),
                    (stat['color'] as Color).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (stat['color'] as Color).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stat['value'] as String,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stat['label'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoCard() {
    final infoItems = [
      {'icon': Icons.work_outline, 'label': 'Role', 'value': userRole},
      {'icon': Icons.trending_up, 'label': 'Experience', 'value': userLevel},
      {'icon': Icons.email_outlined, 'label': 'Email', 'value': email},
      {'icon': Icons.calendar_today, 'label': 'Member Since', 'value': '2024'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Personal Information",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...infoItems
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              item['value'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final settings = [
      {
        'icon': Icons.person_outline,
        'title': 'Change Username',
        'color': primaryColor,
        'onTap': _showUsernameDialog,
      },
      
      {
        'icon': Icons.security,
        'title': 'Privacy & Security',
        'color': const Color(0xFFEF4444),
        'onTap': () {},
      },
      {
        'icon': Icons.help_outline,
        'title': 'Help & Support',
        'color': const Color(0xFF3B82F6),
        'onTap': () {},
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...settings.map((setting) {
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (setting['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  setting['icon'] as IconData,
                  color: setting['color'] as Color,
                  size: 20,
                ),
              ),
              title: Text(setting['title'] as String),
              trailing: const Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey,
              ),
              onTap: setting['onTap'] as VoidCallback?,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 20),
        ),
        title: const Text("Logout", style: TextStyle(color: Colors.red)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.red),
        onTap: _logout,
      ),
    );
  }
}
