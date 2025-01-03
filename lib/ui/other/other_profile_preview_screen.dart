import 'package:flutter/material.dart';
import 'package:photo_sharing_app/services/auth/auth_service.dart';
import 'package:photo_sharing_app/DI/service_locator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:photo_sharing_app/services/profile/profile_services.dart';
import 'package:photo_sharing_app/ui/other/other_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class OtherProfilePreviewScreen extends StatefulWidget {
  final String whichProfile;
  final String otherUid;

  const OtherProfilePreviewScreen({
    required this.whichProfile,
    required this.otherUid,
  });

  @override
  _OtherPreviewScreenState createState() => _OtherPreviewScreenState();
}

ProfileServices profileServices = ProfileServices();

final AuthServices _authServices = locator.get();
String? uid = _authServices.getCurrentuser()!.uid;
String? email = _authServices.getCurrentuser()!.email;
String? imageURL;

String username = '未定', name = '未定';
List<dynamic> like = [], dislike = [], favourite = [];
bool isLikeClickable = true,
    isDislikeClickable = true,
    isFavouriteClickable = true;

class _OtherPreviewScreenState extends State<OtherProfilePreviewScreen> {
  ScrollController _scrollController = ScrollController();
  TextEditingController _commentController = TextEditingController();
  bool isCommenting = false; // To track if comment input is visible
  String commentText = ""; // To store the comment text
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    _setUpProfilePreview();
    super.initState();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        400,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _setUpProfilePreview() async {
    final fetchedURL = await getWhichProfileUrl();
    var user = await _authServices.getDocument(widget.otherUid);
    List<Map<String, dynamic>> fetchedComments =
        await otherService.getAllComments(widget.otherUid, widget.whichProfile);
    if (mounted) {
      setState(() {
        comments = fetchedComments;
      });
      if (user != null) {
        setState(() {
          username = user['username'];
          name = user['name'];
          final favouriteWhichProfile = 'favourite-${widget.whichProfile}';
          final likeWhichProfile = 'like-${widget.whichProfile}';
          final disLikeWhichProfile = 'dislike-${widget.whichProfile}';
          like = user[likeWhichProfile] ?? [];
          dislike = user[disLikeWhichProfile] ?? [];
          favourite = user[favouriteWhichProfile] ?? [];
        });
        setState(() {
          imageURL = fetchedURL;
        });
      }
    }
  }

  Future<void> shareInternetImage(String imageUrl, String fileName) async {
    try {
      // 1. Fetch the image from the internet
      final http.Response response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        // 2. Get a temporary directory to save the file
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$fileName';

        // 3. Write the image bytes to a local file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // 4. Share the image file
        await Share.shareXFiles([XFile(filePath)],
            text: 'Check out this image!');
      } else {
        print('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sharing image: $e');
    }
  }

  Future<String> getWhichProfileUrl() async {
    try {
      final profileRef = FirebaseStorage.instance
          .ref()
          .child("images/${widget.otherUid}/${widget.whichProfile}");
      String profileUrl = await profileRef.getDownloadURL();
      return profileUrl;
    } catch (e) {
      print(e);
      if (widget.whichProfile == 'firstProfileImage')
        return profileServices.firstURL;
      else if (widget.whichProfile == 'secondProfileImage')
        return profileServices.secondURL;
      else if (widget.whichProfile == 'thirdProfileImage')
        return profileServices.thirdURL;
      return profileServices.forthURL;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return SafeArea(
          child: Scaffold(
              appBar: AppBar(
                toolbarHeight: 36,
                title: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.576,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )),
                      MyMenuButton()
                    ],
                  ),
                ),
              ),
              backgroundColor: Colors.black,
              body: Stack(children: [
                SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(children: [
                      // SizedBox(
                      //   height: 48,
                      // ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                              width: MediaQuery.of(context).size.width * 0.97,
                              height: MediaQuery.of(context).size.height * 0.76,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.0),
                                  color: Colors.grey,
                                  image: DecorationImage(
                                    image: NetworkImage(imageURL!),
                                    fit: BoxFit.cover,
                                  ))),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 15),
                          IconButton(
                            onPressed: () async {
                              Map<String, dynamic>? user =
                                  await _authServices.getUserDetail(uid!);
                              setState(() {
                                _scrollToBottom();
                                isCommenting = !isCommenting;
                                username = user?['username'];
                              });
                            },
                            icon: Icon(Icons.chat_bubble_outline),
                          ),
                          Text(comments.length.toString()),
                          SizedBox(width: 30),
                          IconButton(
                            onPressed: () {
                              isLikeClickable
                                  ? setState(() {
                                      otherService.increamentLike(
                                          widget.otherUid, widget.whichProfile);
                                      isLikeClickable = false;
                                      isDislikeClickable = true;
                                      _setUpProfilePreview();
                                    })
                                  : setState(() {
                                      otherService.decreamentDislike(
                                          widget.otherUid, widget.whichProfile);
                                    });
                            },
                            icon: Icon(Icons.thumb_up),
                          ),
                          Text(like.length.toString()),
                          SizedBox(width: 30),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                otherService.increamentDislike(
                                    widget.otherUid, widget.whichProfile);
                                isDislikeClickable = false;
                                isLikeClickable = true;
                                _setUpProfilePreview();
                              });
                            },
                            icon: Icon(Icons.thumb_down),
                          ),
                          Text(dislike.length.toString()),
                          SizedBox(width: 30),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                otherService.increamentFavourite(
                                    widget.otherUid, widget.whichProfile);
                                _setUpProfilePreview();
                              });
                            },
                            icon: Icon(Icons.favorite_outline),
                          ),
                          Text(favourite.length.toString()),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [Text(username), Text(name)],
                      ),
                      isCommenting
                          ? SizedBox(
                              height: 0,
                            )
                          : SizedBox(
                              height: 50,
                            ),
                      if (isCommenting) ...[
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  Colors.white, // Set the border color to white
                              width: 2.0, // Set the width of the border
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(
                                8.0)), // Optional: Add rounded corners
                          ),
                          child: ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              var comment = comments[index];
                              var timestamp = comment['timestamp'];
                              var otherUid = comment['uid'];

                              String formattedTimestamp = timestamp != null
                                  ? timestamp
                                      .toDate()
                                      .toString() // Format the timestamp if not null
                                  : 'No timestamp available';

                              return FutureBuilder(
                                future: _authServices.getDocument(otherUid),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return ListTile(
                                      title: Text(comment['comment']),
                                      subtitle: Text(
                                          'ユーザー: ローディング...'), ///////////////////loading
                                      trailing: Text(formattedTimestamp),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return ListTile(
                                      title: Text(comment['comment']),
                                      subtitle:
                                          Text('ユーザー: Error loading user'),
                                      trailing: Text(formattedTimestamp),
                                    );
                                  }

                                  var otherUser = snapshot.data;
                                  var otherUserName =
                                      otherUser?['username'] ?? 'Unknown User';

                                  return ListTile(
                                    title: Text(comment['comment']),
                                    subtitle: Text('ユーザー: $otherUserName'),
                                    trailing: Text(formattedTimestamp),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              labelText: 'コメントを入力',
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.cancel),
                                onPressed: () {
                                  setState(() {
                                    isCommenting = false;
                                    _commentController.clear();
                                  });
                                },
                              ),
                            ),
                            onChanged: (text) {
                              setState(() {
                                commentText = text;
                              });
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (commentText.isNotEmpty) {
                              otherService.addComment(widget.otherUid,
                                  commentText, widget.whichProfile);
                              setState(() {
                                _setUpProfilePreview();
                                _commentController
                                    .clear(); // Clear the text field
                              });
                            }
                          },
                          child: Text(
                              style: TextStyle(color: Colors.white), 'コメント投稿'),
                        ),
                      ]
                    ])),
                Positioned(
                  bottom: 0,
                  left: 0, // Adjusted to account for padding
                  child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.undo)),
                ),
              ])));
    } catch (e) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Error loading image: $e',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }
  }

  Widget MyMenuButton() {
    return SizedBox(
        width: 55,
        child: PopupMenuButton<String>(
          // color: Color.fromRGBO(0, 0, 0, 0),
          offset: Offset(0, 30),
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          menuPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          position: PopupMenuPosition.over,
          child: TextButton(
            onPressed: null,
            child: Text(
              ". . .",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
          constraints: BoxConstraints(
            maxHeight: 100,
            maxWidth: 80,
          ),
          onSelected: (value) async {
            if (value == "report") {
              setState(() {});
              print("Report selected");
            } else if (value == "share") {
              await shareInternetImage(imageURL!, widget.whichProfile);
              Future.delayed(Duration(seconds: 1), () {
                Navigator.pop(context);
              });
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                value: "report",
                child: Container(
                  alignment: Alignment.center,
                  width: 100, // Set width here
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(149, 0, 0, 0),

                    // Background color
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: Text(
                    "報告",
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
              PopupMenuItem(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                value: "share",
                child: Container(
                  alignment: Alignment.center,
                  width: 100, // Set width here
                  padding: EdgeInsets.symmetric(
                      vertical: 6, horizontal: 0), // Add padding
                  decoration: BoxDecoration(
                    color:
                        const Color.fromARGB(149, 5, 4, 4), // Background color

                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: Text(
                    "投稿",
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              )
            ];
          },
        ));
  }
}
