import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const ProfileScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isEditing = false;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  List<String> _skills = ['Flutter', 'Dart', 'UI/UX', 'Firebase'];
  String _newSkill = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
    _nameController.text = 'Harsh Doshi';
    _emailController.text = 'harshdoshi@marwadinuiversity.ac.in';
    _bioController.text = 'Passionate developer with focus on creating beautiful mobile experiences';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ));

    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF03A9F4), // Consistent blue
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _toggleEditMode,
          ),
          IconButton(
            icon: Icon(Icons.brightness_6, color: theme.onPrimary),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildProfileHeader(theme),
                const SizedBox(height: 16),
                _buildAnimatedInfoCard('Personal Information', [
                  _buildEditableField('Name', _nameController, _isEditing, theme),
                  _buildEditableField('Email', _emailController, _isEditing, theme),
                  _buildInfoRow('Phone', '+91 9313670684', theme),
                  _buildInfoRow('Batch', '2022-2026', theme),
                ], theme),
                _buildAnimatedInfoCard('Academic Information', [
                  _buildInfoRow('Department', 'Information & Communication Technology', theme),
                  _buildInfoRow('Semester', '6th', theme),
                  _buildInfoRow('CGPA', '8.8', theme),
                  _buildInfoRow('Rank', 'Top 10', theme),
                  _buildInfoRow('Attendance', '85%', theme),
                ], theme),
                _buildAnimatedInfoCard('Skills', [
                  if (_isEditing) _buildAddSkillField(),
                  ..._skills.map((skill) => _buildSkillItem(skill, _isEditing, theme)).toList(),
                ], theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Save changes to backend would go here
      }
    });
  }

  Widget _buildProfileHeader(ColorScheme theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _isEditing ? _changeProfilePicture : null,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: theme.secondaryContainer,
            child: Icon(Icons.person, size: 50, color: theme.onSecondaryContainer),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Harsh Doshi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.onBackground,
          ),
        ),
        Text(
          'ICT2025002',
          style: TextStyle(
            fontSize: 16,
            color: theme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _changeProfilePicture() {
    // Implement photo change
  }

  Widget _buildAnimatedInfoCard(String title, List<Widget> children, ColorScheme theme) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primary,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, bool enabled, ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: enabled
                ? TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  )
                : Text(
                    controller.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.onSurface,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSkillField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Add new skill',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => _newSkill = value,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() => _skills.add(value));
                  _newSkill = '';
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (_newSkill.isNotEmpty) {
                setState(() => _skills.add(_newSkill));
                _newSkill = '';
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkillItem(String skill, bool isEditing, ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.code, size: 20, color: theme.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              skill,
              style: TextStyle(fontSize: 16, color: theme.onSurface),
            ),
          ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => setState(() => _skills.remove(skill)),
            ),
        ],
      ),
    );
  }
}
