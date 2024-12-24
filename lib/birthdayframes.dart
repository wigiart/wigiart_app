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
  String currentCategory = 'simple';
  String? selectedFrame;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birthday Frames'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
                  child: const Text('Simple Frames',
                      style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => currentCategory = 'cat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        currentCategory == 'cat' ? Colors.purple : Colors.grey,
                  ),
                  child: const Text(
                    'Cat Frames',
                    style: TextStyle(color: Colors.black),
                  ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FrameEditPage(
                          framePath: frames[currentCategory]![index],
                        ),
                      ),
                    );
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

class FrameEditPage extends StatefulWidget {
  final String framePath;

  const FrameEditPage({
    super.key,
    required this.framePath,
  });

  @override
  State<FrameEditPage> createState() => _FrameEditPageState();
}

class _FrameEditPageState extends State<FrameEditPage> {
  File? _image;
  final picker = ImagePicker();
  final screenshotController = ScreenshotController();
  Uint8List? webImage;

  Future<void> _pickImage() async {
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
    } else {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> saveImage() async {
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
        Navigator.pop(context);
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
    final blob = html.Blob([image]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url);
    anchor.setAttribute("download",
        "framed_image_${DateTime.now().millisecondsSinceEpoch}.png");
    anchor.style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();

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
    if ((kIsWeb && webImage == null) || (!kIsWeb && _image == null)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Image.asset(
              widget.framePath,
              fit: BoxFit.contain,
            ),
          ),
          Center(
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRect(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
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
                    enableRotation: false,
                    tightMode: true,
                    filterQuality: FilterQuality.high,
                    customSize: Size.square(MediaQuery.of(context).size.width * 0.8),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              widget.framePath,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Photo'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_image != null || webImage != null) ...[
            IconButton(
              icon: const Icon(Icons.photo_library),
              onPressed: _pickImage,
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: saveImage,
            ),
          ],
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Screenshot(
          controller: screenshotController,
          child: AspectRatio(
            aspectRatio: 1,
            child: _buildEditableImage(),
          ),
        ),
      ),
    );
  }
}
