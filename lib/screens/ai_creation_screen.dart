import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; 
import '../providers/vault_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart'; 

class AICreationScreen extends StatefulWidget {
  const AICreationScreen({super.key});

  @override
  State<AICreationScreen> createState() => _AICreationScreenState();
}

class _AICreationScreenState extends State<AICreationScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ImagePicker _picker = ImagePicker(); 

  String? _userAvatar; 
  bool _isLoading = false; 
  String? _generatedImageUrl; 
  Uint8List? _generatedImageBytes; 
  String? _errorMessage; 
  File? _uploadedImage; 

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
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _uploadedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to pick image.";
      });
    }
  }

  void _clearUploadedImage() {
    setState(() {
      _uploadedImage = null;
    });
  }

  Future<void> _generateImage() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a prompt first.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _generatedImageUrl = null;
      _generatedImageBytes = null;
    });

    FocusScope.of(context).unfocus();

    try {
      String cleanPrompt = text.replaceAll('\n', ' ');
      String styleKeywords = "masterpiece, highly detailed anime illustration, cinematic dramatic lighting, rich deep contrast, glowing neon accents, sharp detailed eyes, vibrant colors, trending on artstation, aesthetic key visual";
      String finalPrompt = "$cleanPrompt, $styleKeywords";
      String encodedPrompt = Uri.encodeComponent(finalPrompt);
      int randomSeed = DateTime.now().millisecondsSinceEpoch % 1000000;
      
      String primaryUrl = 'https://image.pollinations.ai/prompt/$encodedPrompt?seed=$randomSeed&width=512&height=512&nologo=true&model=turbo'; 

      http.Response? response;
      
      try {
        response = await http.get(
          Uri.parse(primaryUrl),
          headers: {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
            "Accept": "image/*",
          },
        ).timeout(const Duration(seconds: 40));
      } catch (e) {
        debugPrint(e.toString());
      }

      if (response == null || response.statusCode != 200) {
        try {
          String backupUrl = 'https://pollinations.ai/p/$encodedPrompt?seed=$randomSeed&width=512&height=512';
          response = await http.get(
            Uri.parse(backupUrl),
            headers: {
              "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
              "Accept": "image/*",
            },
          ).timeout(const Duration(seconds: 40));
        } catch (e) {
          debugPrint(e.toString());
        }
      }

      if (response != null && response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          _generatedImageUrl = primaryUrl;
          _generatedImageBytes = response!.bodyBytes;
          _isLoading = false;
        });

        try {
          final user = FirebaseAuth.instance.currentUser; 
          if (user != null) {
            await FirebaseFirestore.instance.collection('user_images').add({
              'userId': user.uid, 
              'imageUrl': primaryUrl, 
              'prompt': text, 
              'timestamp': FieldValue.serverTimestamp(), 
            });
          }
        } catch (e) {
          debugPrint(e.toString()); 
        }
        
        if (mounted) {
          Provider.of<VaultProvider>(context, listen: false).addImageToVault(primaryUrl);
        }
      } else {
        throw Exception("Failed to load image");
      }

    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Network timeout or connection blocked.\nPlease check your Internet connection.";
        _isLoading = false;
      });
    }
  }

  void _showHistoryBottomSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login first.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      isDismissible: true, 
      enableDrag: true,    
      backgroundColor: Colors.transparent, 
      builder: (BuildContext context) {
        return HistorySheetContent(userId: user.uid);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Otaku Universe'),
            const SizedBox(width: 8),
            Icon(
              Icons.auto_awesome_rounded, 
              color: Colors.purpleAccent[100] ?? Colors.purpleAccent,
              size: 20,
            ),
          ],
        ), 
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_uploadedImage != null)
              Stack(
                children: [
                  Container(
                    height: 90,
                    width: 90,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple, width: 2),
                      image: DecorationImage(
                        image: FileImage(_uploadedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -10,
                    right: -10,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.redAccent),
                      onPressed: _clearUploadedImage,
                    ),
                  ),
                ],
              ),

            TextField(
              controller: _promptController,
              decoration: InputDecoration(
                labelText: 'Enter your prompt (e.g., Cyberpunk Samurai)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                prefixIcon: const Icon(Icons.brush),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_photo_alternate, color: Colors.deepPurpleAccent),
                  onPressed: _pickImage,
                  tooltip: 'Upload reference image',
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateImage, 
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 10),
                        Text('AI is painting...', style: TextStyle(fontSize: 15)),
                      ],
                    )
                  : const Text('Generate AI Image', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurple, width: 2),
                ),
                child: _buildResultArea(),
              ),
            ),
            
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.history, color: Colors.deepPurpleAccent),
              label: const Text(
                'View History', 
                style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 15, fontWeight: FontWeight.bold)
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showHistoryBottomSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.deepPurpleAccent),
            SizedBox(height: 14),
            Text(
              'Generating AI magic...\nPlease wait ~5 seconds',
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 13),
            ),
          ],
        ),
      );
    } else if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      );
    } else if (_generatedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          _generatedImageBytes!, 
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else {
      return const Center(
        child: Text(
          'Your generated anime image will appear here', 
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
  }
}

class HistorySheetContent extends StatefulWidget {
  final String userId;
  const HistorySheetContent({super.key, required this.userId});

  @override
  State<HistorySheetContent> createState() => _HistorySheetContentState();
}

class _HistorySheetContentState extends State<HistorySheetContent> {
  late Stream<QuerySnapshot> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = FirebaseFirestore.instance
        .collection('user_images')
        .where('userId', isEqualTo: widget.userId)
        .snapshots();
  }

  Future<void> _deleteImage(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('user_images').doc(docId).delete();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _downloadImage(BuildContext context, String url) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Downloading image...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": "Mozilla/5.0"},
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image downloaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception("Failed to fetch image data.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openImagePreview(BuildContext context, String imageUrl, String prompt) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.8,
                  maxScale: 4.5,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    headers: const {"User-Agent": "Mozilla/5.0"},
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.purpleAccent),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 60),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          prompt,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadImage(context, imageUrl),
                    icon: const Icon(Icons.download_rounded, color: Colors.white),
                    label: const Text('Download Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).pop(); 
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.65, 
        minChildSize: 0.4,     
        maxChildSize: 0.95,     
        builder: (BuildContext context, ScrollController scrollController) {
          return GestureDetector(
            onTap: () {}, 
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1B1A24),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    'My Generation History', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  const SizedBox(height: 10),
                  
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _historyStream, 
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                          ));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No images generated yet.', style: TextStyle(color: Colors.grey)));
                        }

                        final List<DocumentSnapshot> docs = snapshot.data!.docs.toList();
                        
                        docs.sort((a, b) {
                          final Map<String, dynamic>? aData = a.data() as Map<String, dynamic>?;
                          final Map<String, dynamic>? bData = b.data() as Map<String, dynamic>?;
                          
                          final Timestamp? aTime = aData?['timestamp'] as Timestamp?;
                          final Timestamp? bTime = bData?['timestamp'] as Timestamp?;
                          
                          if (aTime == null && bTime == null) return 0; 
                          if (aTime == null) return 1;
                          if (bTime == null) return -1;
                          return bTime.compareTo(aTime); 
                        });

                        return GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, 
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            var data = docs[index].data() as Map<String, dynamic>;
                            String docId = docs[index].id;
                            String imageUrl = data['imageUrl'] ?? '';
                            String prompt = data['prompt'] ?? 'No prompt';

                            return GestureDetector(
                              onTap: () => _openImagePreview(context, imageUrl, prompt),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl, 
                                      fit: BoxFit.cover,
                                      cacheWidth: 300,
                                      cacheHeight: 300,
                                      headers: const {"User-Agent": "Mozilla/5.0"},
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade900,
                                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.65),
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.download, color: Colors.white, size: 20),
                                            onPressed: () => _downloadImage(context, imageUrl),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                            onPressed: () => _deleteImage(docId),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        prompt, 
                                        maxLines: 1, 
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}