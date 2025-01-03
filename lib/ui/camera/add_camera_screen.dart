import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:photo_sharing_app/ui/camera/captures_screen.dart';
import 'package:photo_sharing_app/ui/camera/post_preview_screen.dart';
// import 'package:photo_sharing_app/ui/camera/preview_screen.dart';
// import 'package:photo_sharing_app/ui/camera/profile_set_screen.dart';
// import 'package:photo_sharing_app/ui/screen/post_screen.dart';

import '../../main.dart';

class AddCameraScreen extends StatefulWidget {
  const AddCameraScreen({super.key});

  @override
  _AddCameraScreenState createState() => _AddCameraScreenState();
}

class _AddCameraScreenState extends State<AddCameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  bool _isRearCameraSelected = true;
  FlashMode? _currentFlashMode;

  List<File> allFileList = [];

  final resolutionPresets = ResolutionPreset.ultraHigh;

  ResolutionPreset currentResolutionPreset = ResolutionPreset.ultraHigh;

  getPermissionStatus() async {
    await Permission.camera.request();
    await refreshAlreadyCapturedImages();
    var status = await Permission.camera.status;

    if (status.isGranted) {
      log('Camera Permission: GRANTED');
      setState(() {
        _isCameraPermissionGranted = true;
      });
      // Set and initialize the new camera
      onNewCameraSelected(cameras[1]);
      refreshAlreadyCapturedImages();
    } else {
      log('Camera Permission: DENIED');
    }
  }

  refreshAlreadyCapturedImages() async {
    final directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> fileList = await directory.list().toList();
    allFileList.clear();
    List<Map<int, dynamic>> fileNames = [];

    fileList.forEach((file) {
      if (file.path.contains('.jpg')) {
        allFileList.add(File(file.path));

        String name = file.path.split('/').last.split('.').first;
        fileNames.add({0: int.parse(name), 1: file.path.split('/').last});
      }
    });
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;

    if (cameraController!.value.isTakingPicture) {
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      print('Error occured while taking picture: $e');
      return null;
    }
  }

  Future<void> _toggleFlashMode(FlashMode mode) async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      await controller!.setFlashMode(mode);
      setState(() => _currentFlashMode = mode);
    } catch (e) {
      log('Error setting flash mode: $e');
    }
  }

  void resetCameraValues() async {}

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;

    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await previousCameraController?.dispose();

    resetCameraValues();

    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();

      _currentFlashMode = controller!.value.flashMode;
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    controller!.setExposurePoint(offset);
    controller!.setFocusPoint(offset);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
    getPermissionStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    // Remove the lifecycle observer to prevent potential null errors.
    WidgetsBinding.instance.removeObserver(this);

    // Dispose of the CameraController if it exists.
    if (controller != null) {
      controller?.dispose();
      controller = null; // Nullify the controller reference for safety.
    }

    // Call super.dispose to ensure proper cleanup.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isCameraPermissionGranted
            ? _isCameraInitialized
                ? Column(
                    children: [
                      SizedBox(
                        height: 15,
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.78,
                        width: MediaQuery.of(context).size.width * 0.99,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(340.0),
                          color: Colors.black,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(38.0),
                          child: CameraPreview(controller!),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          8.0,
                          16.0,
                          8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<FlashMode>(
                                    value: _currentFlashMode,
                                    icon: const SizedBox.shrink(),
                                    alignment: Alignment.topLeft,
                                    dropdownColor:
                                        const Color.fromARGB(99, 21, 22, 21),
                                    onChanged: (FlashMode? newMode) {
                                      if (newMode != null) {
                                        _toggleFlashMode(newMode);
                                      }
                                    },
                                    items: [
                                      DropdownMenuItem<FlashMode>(
                                        value: FlashMode.off,
                                        child: Icon(
                                          Icons.flash_off,
                                          size: 30,
                                          color:
                                              _currentFlashMode == FlashMode.off
                                                  ? Colors.yellow
                                                  : Colors.white,
                                        ),
                                      ),
                                      DropdownMenuItem<FlashMode>(
                                        value: FlashMode.auto,
                                        child: Icon(
                                          Icons.flash_auto,
                                          size: 30,
                                          color: _currentFlashMode ==
                                                  FlashMode.auto
                                              ? Colors.yellow
                                              : Colors.white,
                                        ),
                                      ),
                                      DropdownMenuItem<FlashMode>(
                                        value: FlashMode.always,
                                        child: Icon(
                                          size: 30,
                                          Icons.flash_on,
                                          color: _currentFlashMode ==
                                                  FlashMode.always
                                              ? Colors.yellow
                                              : Colors.white,
                                        ),
                                      ),
                                      DropdownMenuItem<FlashMode>(
                                        value: FlashMode.torch,
                                        child: Icon(
                                          Icons.highlight,
                                          size: 30,
                                          color: _currentFlashMode ==
                                                  FlashMode.torch
                                              ? Colors.yellow
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    XFile? rawImage = await takePicture();
                                    File imageFile = File(rawImage!.path);

                                    int currentUnix =
                                        DateTime.now().millisecondsSinceEpoch;

                                    final directory =
                                        await getApplicationDocumentsDirectory();

                                    String fileFormat =
                                        imageFile.path.split('.').last;

                                    print(fileFormat);

                                    await imageFile.copy(
                                      '${directory.path}/$currentUnix.$fileFormat',
                                    );
                                    // setState(() {});
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PostPreviewScreen(),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(
                                        Icons.radio_button_unchecked,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isCameraInitialized = false;
                                    });
                                    onNewCameraSelected(
                                        cameras[_isRearCameraSelected ? 1 : 0]);
                                    setState(() {
                                      _isRearCameraSelected =
                                          !_isRearCameraSelected;
                                    });
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        _isRearCameraSelected
                                            ? Icons.camera_front
                                            : Icons.camera_rear,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      '読み込み中',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(),
                  Text(
                    'Permission denied',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      getPermissionStatus();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Give permission',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> deleteFileWithConfirmation(
    BuildContext context,
  ) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('削除の確認'),
          content: const Text('すでに撮影した画像を本当に削除しますか？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // User pressed Cancel
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // User pressed Delete
              },
              child: const Text(
                '削除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        List<File> filesToRemove = [];
        showDialog(
            context: context,
            builder: (context) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            });
        for (final File file in allFileList) {
          if (await file.exists()) {
            await file.delete(); // Delete each file
            filesToRemove.add(file); // Mark the file for removal
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ファイルが存在しません。')),
            );
          }
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ファイルの削除に失敗しました: $e')),
        );
      }
    }
  }
}
