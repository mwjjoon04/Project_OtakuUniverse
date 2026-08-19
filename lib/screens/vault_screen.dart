import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'profile_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  String? _userAvatar; 

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();
  }

  void _loadUserAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists && doc.data() != null) {
        setState(() {
          _userAvatar = doc.data()!['avatarUrl'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Images'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) => _loadUserAvatar()); 
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.deepPurpleAccent,
                backgroundImage: _userAvatar != null && _userAvatar!.isNotEmpty
                    ? AssetImage(_userAvatar!)
                    : null,
                child: (_userAvatar == null || _userAvatar!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text("Please login first.", style: TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user_images') 
                  .where('userId', isEqualTo: user.uid) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Your cloud vault is empty. Go create something!',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final images = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final doc = images[index]; 
                    final data = doc.data() as Map<String, dynamic>;
                    final imageUrl = data['imageUrl'] ?? '';

                    return InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.grey[900],
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.open_in_browser, color: Colors.blueAccent),
                                  title: const Text('Open in Browser to Save', style: TextStyle(color: Colors.white)),
                                  onTap: () async {
                                    Navigator.pop(context); 
                                    final Uri url = Uri.parse(imageUrl);
                                    if (!await launchUrl(url)) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch browser')));
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                                  title: const Text('Delete from Cloud', style: TextStyle(color: Colors.redAccent)),
                                  onTap: () async {
                                    Navigator.pop(context); 
                                    await FirebaseFirestore.instance.collection('user_images').doc(doc.id).delete();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image deleted!')));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}