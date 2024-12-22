import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditionally import dart:html only for web
import 'web_utils.dart' if (dart.library.html) 'dart:html' as html;

class BirthdayFrameWithPets extends StatefulWidget {
  const BirthdayFrameWithPets({super.key});

  @override
  State<BirthdayFrameWithPets> createState() => _BirthdayFrameWithPetsState();
}

class _BirthdayFrameWithPetsState extends State<BirthdayFrameWithPets> {
  File? _image;
  String? selectedFrame;
  final picker = ImagePicker();
  String currentCategory = 'simple';
  final screenshotController = ScreenshotController();
  Uint8List? webImage;

  final Map<String, List<String>> frames = {
    'simple': [
      'assets/frames/simple_frames/frame1.webp',
      'assets/frames/simple_frames/frame2.webp',
      'assets/frames/simple_frames/frame3.webp',
      'assets/frames/simple_frames/frame4.webp',
      'assets/frames/simple_frames/frame5.webp',
      'assets/frames/simple_frames/frame6.webp',
      'assets/frames/simple_frames/frame7.webp',
    ],
    'cat': [
      'assets/frames/cat_frames/cat_frame1.png',
    ],
  };

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        var bytes = await pickedFile.readAsBytes();
        setState(() {
          webImage = bytes;
        });
      } else {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
      _showEditDialog();
    }
  }

  Future<void> saveImage() async {
    if ((kIsWeb && webImage == null) ||
        (!kIsWeb && _image == null) ||
        selectedFrame == null) {
      return;
    }

    try {
      final Uint8List? image = await screenshotController.capture(
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 10),
      );

      if (image == null) return;

      if (kIsWeb) {
        await saveImageWeb(image);
      } else {
        await saveImageMobile(image);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
    }
  }

  Future<void> saveImageWeb(Uint8List image) async {
    if (!kIsWeb) return;
    // Create a blob from the image data
    final blob = html.Blob([image]); // Ensure image is wrapped in a list
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url);
    anchor.setAttribute("download",
        "framed_image_${DateTime.now().millisecondsSinceEpoch}.png");
    anchor.style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();

    // Clean up
    Future.delayed(const Duration(milliseconds: 100), () {
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    });
  }

  Future<void> saveImageMobile(Uint8List image) async {
    if (kIsWeb) return;

    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
        '${directory.path}/framed_image_${DateTime.now().millisecondsSinceEpoch}.png';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(image);
    await GallerySaver.saveImage(imagePath);
  }

  Widget _buildEditableImage() {
    return Container(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: PhotoView(
              imageProvider: kIsWeb
                  ? MemoryImage(webImage!)
                  : FileImage(_image!) as ImageProvider,
              backgroundDecoration:
                  const BoxDecoration(color: Colors.transparent),
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 2,
              initialScale: PhotoViewComputedScale.contained,
              basePosition: Alignment.center,
            ),
          ),
          Image.asset(
            selectedFrame!,
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    if ((kIsWeb && webImage == null) ||
        (!kIsWeb && _image == null) ||
        selectedFrame == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Edit Photo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Screenshot(
                  controller: screenshotController,
                  child: _buildEditableImage(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: saveImage,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birthday Frames'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => currentCategory = 'simple'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentCategory == 'simple'
                        ? Colors.purple
                        : Colors.grey,
                  ),
                  child: const Text('Simple Frames'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => currentCategory = 'cat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        currentCategory == 'cat' ? Colors.purple : Colors.grey,
                  ),
                  child: const Text('Cat Frames'),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: frames[currentCategory]?.length ?? 0,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFrame = frames[currentCategory]![index];
                    });
                    getImage();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedFrame == frames[currentCategory]![index]
                            ? Colors.purple
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Image.asset(
                      frames[currentCategory]![index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
