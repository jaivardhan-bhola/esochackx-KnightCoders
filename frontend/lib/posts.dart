import 'dart:io';
import 'package:civicsense/healthcheck.dart';
import 'package:civicsense/officialHome.dart';
import 'package:civicsense/widgets/parallelogram_shape.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:civicsense/Profile.dart';
import 'package:civicsense/chatbot.dart';
import 'package:civicsense/Home.dart';
import 'package:civicsense/services/postApiService.dart';
import 'package:timeago/timeago.dart' as timeago;

class Posts extends StatefulWidget {
  const Posts({Key? key}) : super(key: key);

  @override
  State<Posts> createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  List<dynamic> posts = [];
  bool isLoading = true;
  bool isCreatingPost = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedMedia;
  final ImagePicker _picker = ImagePicker();
  var box = Hive.box('appBox');
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedPosts = await PostApiService.getPosts();

      // Sort posts by creation date (newest first)
      fetchedPosts.sort((a, b) {
        DateTime dateA = DateTime.parse(a['createdAt']);
        DateTime dateB = DateTime.parse(b['createdAt']);
        return dateB.compareTo(dateA); // Descending order (newest first)
      });

      setState(() {
        posts = fetchedPosts;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedMedia = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error picking image: $e');
    }
  }

  Future<void> _submitPost() async {
    if (_titleController.text.isEmpty) {
      _showErrorSnackBar(context, 'Please enter a title for your post');
      return;
    }

    try {
      setState(() {
        isCreatingPost = true;
      });

      bool success = await PostApiService.createPost(
        title: _titleController.text,
        description: _descriptionController.text,
        mediaFile: _selectedMedia,
        userId: box.get('userId'),
      );

      if (success) {
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedMedia = null;
          isCreatingPost = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post created successfully')),
        );
        await fetchPosts();
      } else {
        setState(() {
          isCreatingPost = false;
        });
        _showErrorSnackBar(context, 'Failed to create post');
      }
    } catch (e) {
      setState(() {
        isCreatingPost = false;
      });
      _showErrorSnackBar(context, 'Error: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Gallery'),
                onTap: () {
                  _pickMedia(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  _pickMedia(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePostSheet() {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.5,
            maxChildSize: 0.85,
            expand: false,
            builder: (_, scrollController) {
              return Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Create New Post',
                          style: GoogleFonts.instrumentSans(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A59D1),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(height: 16, thickness: 2),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: 'Enter post title...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Color(0xFF3A59D1)),
                              ),
                              contentPadding: EdgeInsets.all(16),
                            ),
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'What\'s on your mind?',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Color(0xFF3A59D1)),
                              ),
                              contentPadding: EdgeInsets.all(16),
                            ),
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          if (_selectedMedia != null) ...[
                            Text(
                              'Media Preview',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3A59D1),
                              ),
                            ),
                            SizedBox(height: 8),
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedMedia!,
                                    height: screenHeight * 0.2,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                IconButton(
                                  icon: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.close, color: Colors.red),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedMedia = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.add_photo_alternate),
                                  label: Text('Add Media'),
                                  onPressed: _showImagePickerOptions,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Color(0xFF3A59D1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      isCreatingPost ? null : _submitPost,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3A59D1),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                  ),
                                  child: isCreatingPost
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text('Post'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getTimeAgo(String timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';

    try {
      DateTime parsedDate = DateTime.parse(timestamp);
      return timeago.format(parsedDate);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Profile(),
                ),
              );
            },
            icon: Icon(Icons.person,
                color: Colors.white, size: screenWidth * 0.08),
          ),
        ],
        title: Row(
          children: [
            CircleAvatar(
                backgroundColor: Colors.white,
                radius: screenWidth * 0.05,
                backgroundImage: AssetImage('assets/logo.png')),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'Community',
              style: GoogleFonts.instrumentSans(
                fontSize: screenWidth * 0.06,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ParallelogramButton(
        color: Color(0xFF71B340),
        width: 60,
        height: 50,
        skewAmount: 12.0,
        onPressed: () {
          _showCreatePostSheet();
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          Container(
            height: screenHeight,
            width: screenWidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3D84D6), Color(0xFF3A59D1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.12),
                Expanded(
                  child: Container(
                    width: screenWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: isLoading
                        ? Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: fetchPosts,
                            child: posts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.post_add,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No posts yet',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Be the first to share with the community!',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          icon: Icon(Icons.add),
                                          label: Text('Create Post'),
                                          onPressed: _showCreatePostSheet,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF3A59D1),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: EdgeInsets.only(
                                      bottom: screenHeight * 0.1,
                                      top: screenHeight * 0.02,
                                      left: screenWidth * 0.03,
                                      right: screenWidth * 0.03,
                                    ),
                                    itemCount: posts.length,
                                    itemBuilder: (context, index) {
                                      final post = posts[index];
                                      final user =
                                          post['users_permissions_user'];
                                      final media = post['media'] != null &&
                                              post['media'].isNotEmpty
                                          ? post['media'][0]['formats']
                                              ['thumbnail']
                                          : null;

                                      return Card(
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          side: BorderSide(
                                            color: Color(0xFF3A59D1)
                                                .withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                        margin: EdgeInsets.only(bottom: 20),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white,
                                                Color(0xFFF5F7FF)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(14),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Color(
                                                                    0xFF3A59D1)
                                                                .withOpacity(
                                                                    0.2),
                                                            blurRadius: 8,
                                                            offset:
                                                                Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: CircleAvatar(
                                                        backgroundColor:
                                                            Color(0xFF3A59D1),
                                                        radius: 22,
                                                        child: user != null
                                                            ? Text(
                                                                user['username']
                                                                            ?[0]
                                                                        ?.toUpperCase() ??
                                                                    'U',
                                                                style: GoogleFonts
                                                                    .instrumentSans(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 18,
                                                                ),
                                                              )
                                                            : Icon(Icons.person,
                                                                color: Colors
                                                                    .white),
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            user['username']!,
                                                            style: GoogleFonts
                                                                .instrumentSans(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color: Color(
                                                                  0xFF3A59D1),
                                                            ),
                                                          ),
                                                          SizedBox(height: 4),
                                                          Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                              horizontal: 8,
                                                              vertical: 3,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .amber
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              border:
                                                                  Border.all(
                                                                color: Colors
                                                                    .amber
                                                                    .withOpacity(
                                                                        0.3),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                    Icons
                                                                        .access_time_rounded,
                                                                    size: 12,
                                                                    color: Colors
                                                                            .amber[
                                                                        700]),
                                                                SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  _getTimeAgo(post[
                                                                      'createdAt']),
                                                                  style: GoogleFonts
                                                                      .instrumentSans(
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Colors
                                                                            .amber[
                                                                        700],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 4,
                                                ),
                                                child: Text(
                                                  post['title'],
                                                  style: GoogleFonts
                                                      .instrumentSans(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              if (post['description'] != null &&
                                                  post['description']
                                                      .toString()
                                                      .isNotEmpty)
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  child: Text(
                                                    post['description'],
                                                    style: GoogleFonts
                                                        .instrumentSans(
                                                      fontSize: 15,
                                                      color: Colors.black87
                                                          .withOpacity(0.8),
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              if (media != null)
                                                Container(
                                                  width: screenWidth,
                                                  margin:
                                                      EdgeInsets.only(top: 8),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                      bottom:
                                                          Radius.circular(16),
                                                    ),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.1),
                                                            blurRadius: 8,
                                                            offset:
                                                                Offset(0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Image.network(
                                                        'http://${PostApiService.server_url}${media['url']}',
                                                        fit: BoxFit.cover,
                                                        height: 220,
                                                        width: double.infinity,
                                                        errorBuilder: (context,
                                                                error,
                                                                stackTrace) =>
                                                            Container(
                                                          height: 220,
                                                          color:
                                                              Colors.grey[100],
                                                          child: Center(
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .broken_image_rounded,
                                                                  size: 48,
                                                                  color: Colors
                                                                          .grey[
                                                                      400],
                                                                ),
                                                                SizedBox(
                                                                    height: 8),
                                                                Text(
                                                                  'Image not available',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                            .grey[
                                                                        600],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              else
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    left: 16,
                                                    right: 16,
                                                    bottom: 16,
                                                    top: 8,
                                                  ),
                                                  child: Divider(
                                                    color: Colors.grey
                                                        .withOpacity(0.2),
                                                    thickness: 1,
                                                  ),
                                                ),
                                             
                                                ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                        onPressed: () {
                          var userType = box.get('type');
                          if (userType == 'Official')
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Officialhome(),
                              ),
                            );
                          else
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Home(),
                              ),
                            );
                        },
                        icon: Icon(Icons.home_rounded,
                            color: Colors.white, size: screenWidth * 0.1)),
                    SizedBox(width: screenWidth * 0.05),
                    IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.feed_rounded,
                            color: Colors.white, size: screenWidth * 0.1)),
                    SizedBox(width: screenWidth * 0.05),
                    if (box.get('type') == 'Citizen')
                      IconButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HealthCheck(),
                              ),
                            );
                          },
                          icon: Icon(Icons.medical_services_rounded,
                              color: Colors.white, size: screenWidth * 0.1)),
                    SizedBox(width: screenWidth * 0.05),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
