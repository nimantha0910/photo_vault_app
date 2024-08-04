import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_gallery_app/screens/full_screen_image.dart';
import 'package:photo_gallery_app/utils/app_colors.dart';
import 'package:photo_gallery_app/widgets/custom_dot_indicator.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class ImageUploader extends StatefulWidget {
  const ImageUploader({super.key});

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  final storageRef = FirebaseStorage.instance.ref();
  ImagePicker picker = ImagePicker();
  Map<String, String> imageUrls = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  void uploadImages() async {
    var uuid = const Uuid();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      final imgRef = storageRef.child("${uuid.v4()}.jpg");
      String url = '';
      if (image != null) {
        setState(() {
          isLoading = true;
        });
        File imgFile = File(image.path);
        await imgRef.putFile(imgFile);
        url = await imgRef.getDownloadURL();
        log(url.toString());
      }

      const databaseUrl =
          "https://gallry-cfed5-default-rtdb.firebaseio.com/images.json";
      final response = await http.post(
        Uri.parse(databaseUrl),
        body: json.encode({
          'url': url,
          'uploaded_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        log('Successfully uploaded to Realtime Database');
        setState(() {
          isLoading = true;
        });
        fetchImages();

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image added successfully',
                style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
          ),
        );
      } else {
        log('Failed to upload to Realtime Database: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = true;
      });
      return Future.error(e.toString());
    }
  }

  void fetchImages() async {
    setState(() {
      isLoading = true;
    });
    const databaseUrl =
        "https://gallry-cfed5-default-rtdb.firebaseio.com/images.json";
    final response = await http.get(Uri.parse(databaseUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      setState(() {
        imageUrls =
            data.map((key, value) => MapEntry(key, value['url'] as String));
        isLoading = false;
      });
    } else {
      log('Failed to load images from Realtime Database: ${response.statusCode}');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onImageTap(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(imageUrl: imageUrl),
      ),
    );
  }

  void _deleteImage(String key, String imageUrl) async {
    bool confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    try {
      setState(() {
        isLoading = true;
      });

      final imageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await imageRef.delete();

      final databaseUrl =
          "https://gallry-cfed5-default-rtdb.firebaseio.com/images/$key.json";
      final response = await http.delete(Uri.parse(databaseUrl));

      if (response.statusCode == 200) {
        log('Successfully deleted from Realtime Database');
        setState(() {
          imageUrls.remove(key);
          isLoading = false;
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted successfully',
                style: TextStyle(color: AppColors.black)),
            backgroundColor: AppColors.white,
          ),
        );
      } else {
        log('Failed to delete from Realtime Database: ${response.statusCode}');
        setState(() {
          isLoading = true;
        });
      }
    } catch (e) {
      log('Error: $e');
      setState(() {
        isLoading = true;
      });
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Image'),
              content:
                  const Text('Are you sure you want to delete this image?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.darkblue),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.darkblue),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Photo Vault',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.darkblue,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.add_a_photo_outlined, color: AppColors.white),
            onPressed: uploadImages,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: DotIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        final key = imageUrls.keys.elementAt(index);
                        final url = imageUrls[key]!;
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _onImageTap(url),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width / 3.5,
                                height: MediaQuery.of(context).size.width / 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    fit: BoxFit.cover,
                                    imageUrl: url,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 5.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.white, width: 2.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 24, color: AppColors.white),
                                  onPressed: () => _deleteImage(key, url),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
