import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _changePassword() async {
    TextEditingController passwordController = TextEditingController();
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter new password (min 6 chars)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('UPDATE', style: TextStyle(color: Colors.deepPurpleAccent))
          ),
        ],
      ),
    ) ?? false;

    if (confirm && passwordController.text.length >= 6) {
      try {
        await user?.updatePassword(passwordController.text);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _changeEmail() async {
    TextEditingController emailController = TextEditingController();
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Enter new email address'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('SEND VERIFICATION', style: TextStyle(color: Colors.deepPurpleAccent))
          ),
        ],
      ),
    ) ?? false;

    if (confirm && emailController.text.isNotEmpty) {
      try {
        await user?.verifyBeforeUpdateEmail(emailController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Verification email sent to the new address. Please check your inbox!'),
            duration: Duration(seconds: 4),
          ));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showFeedback() {
    TextEditingController feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: TextField(
          controller: feedbackController,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Tell us how we can improve...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              String feedbackText = feedbackController.text.trim();
              if (feedbackText.isEmpty) return; 

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              navigator.pop();

              try {
                if (user != null) {
                  await FirebaseFirestore.instance.collection('feedbacks').add({
                    'userId': user!.uid,
                    'message': feedbackText,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Thank you! Your feedback has been sent to the developer.'))
                  );
                }
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }, 
            child: const Text('SUBMIT', style: TextStyle(color: Colors.deepPurpleAccent))
          ),
    
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Otaku Universe'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Otaku Universe is your ultimate AI companion app. Generate anime art, chat with your favorite characters, and explore the universe!'),
            SizedBox(height: 10),
            Text('Developed with ❤️ using Flutter & Firebase.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple[800],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text(themeProvider.isDarkMode ? 'Currently in Dark Mode' : 'Currently in Light Mode'),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Colors.deepPurpleAccent,
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(),
          ),
          const Divider(),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Account Security', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Change Email'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changeEmail,
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changePassword,
          ),
          const Divider(),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Support & Info', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Feedback'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showFeedback,
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About (Information)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showAbout,
          ),
        ],
      ),
    );
  }
}