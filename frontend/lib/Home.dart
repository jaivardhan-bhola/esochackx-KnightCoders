import 'package:civicsense/MLApiCalls.dart';
import 'package:civicsense/Profile.dart';
import 'package:civicsense/chatbot.dart';
import 'package:civicsense/posts.dart';
import 'package:civicsense/widgets/parallelogram_shape.dart'; // Import the custom shape
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:civicsense/services/complaintsApiService.dart'; // Import the complaints service
import 'package:hive_flutter/hive_flutter.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController _problemController = TextEditingController();
  String _selectedLocation = 'Sitaburdi'; // Default location
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  var box = Hive.box('appBox');

  final List<String> _locations = [
    'Sitaburdi',
    'Dharampet',
    'IIIT Nagpur',
    'Buttibori'
  ];
  final mlApi = MLApiService();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error picking image: $e');
    }
  }

  // Function to show image picker options (camera or gallery)
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
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
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
                    color: Colors.white, size: screenWidth * 0.08)),
          ],
          title: Row(
            children: [
              CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: screenWidth * 0.05,
                  backgroundImage: AssetImage('assets/logo.png')),
              SizedBox(width: screenWidth * 0.02),
              Text(
                'CivicSense',
                style: GoogleFonts.instrumentSans(
                  fontSize: screenWidth * 0.06,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Replace FloatingActionButton with our custom ParallelogramButton
        floatingActionButton: ParallelogramButton(
          color: Color(0xFF71B340),
          width: 60,
          height: 50,
          skewAmount: 12.0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Chatbot(),
              ),
            );
          },
          child: Icon(Icons.chat_rounded, color: Colors.white),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.15),
                  Image.asset('assets/bot.png', height: screenHeight * 0.235),
                  Container(
                    width: screenWidth,
                    height: screenHeight * 0.552,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(screenWidth * 0.05),
                        topRight: Radius.circular(screenWidth * 0.05),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: screenWidth * 0.05,
                          right: screenWidth * 0.05,
                          top: screenHeight * 0.02,
                          bottom: screenHeight * 0.02,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Describe your problem',
                              style: GoogleFonts.instrumentSans(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            TextField(
                              controller: _problemController,
                              maxLines: null,
                              minLines: 6,
                              expands: false,
                              decoration: InputDecoration(
                                hintText: 'Enter your problem here',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(screenWidth * 0.02),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(screenWidth * 0.02),
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                              ),
                              style: TextStyle(fontSize: screenWidth * 0.04),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Select location',
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_selectedImage != null)
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedImage = null;
                                      });
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.close,
                                            color: Colors.red, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'Remove image',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Container(
                              width: screenWidth * 0.9,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius:
                                    BorderRadius.circular(screenWidth * 0.02),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.02),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedLocation,
                                    isExpanded: true,
                                    hint: Text('Select location'),
                                    items: _locations.map((String location) {
                                      return DropdownMenuItem<String>(
                                        value: location,
                                        child: Text(location),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedLocation = newValue;
                                        });
                                      }
                                    },
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Display selected image preview
                            if (_selectedImage != null) ...[
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                'Image attached',
                                style: GoogleFonts.instrumentSans(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxHeight: screenHeight * 0.15,
                                  ),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: screenHeight * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      // Show loading indicator
                                      _showLoadingDialog(context);

                                      final result =
                                          await mlApi.processComplaint(
                                        complaint: _problemController.text,
                                        location: _selectedLocation,
                                        imageFile: _selectedImage,
                                      );
                                      Map<String, String> parsedcomplainerData =
                                          _parseResponse(
                                              result['complainer_view']);
                                      Map<String, String> parsedOfficerData =
                                          _parseResponse(
                                              result['officer_view']);
                                      print(parsedOfficerData);
                                      print(parsedcomplainerData);
                                      try {
                                        print('Complaint data:');
                                        print(_problemController.text);
                                        print(parsedOfficerData['Summary']);
                                        print('Pending');

                                        // Extract just the number part from severity (in case it's in format "3/5")
                                        String severityString =
                                            parsedOfficerData['Severity'] ??
                                                '1';
                                        int severityValue;
                                        if (severityString.contains('/')) {
                                          severityValue = int.parse(
                                              severityString.split('/')[0]);
                                        } else {
                                          severityValue =
                                              int.parse(severityString);
                                        }

                                        print(severityValue);
                                        print(_selectedLocation);
                                        print(parsedOfficerData['Departments']);
                                        ComplaintsApiService.createComplaint(
                                          longText: _problemController.text,
                                          summarisedText:
                                              parsedOfficerData['Summary'],
                                          complaintStatus: 'Pending',
                                          complaintSeverity: severityValue,
                                          location: _selectedLocation,
                                          department:
                                              parsedOfficerData['Departments'],
                                          imageFile:
                                              _selectedImage, // Pass the selected image file
                                          userId: box.get('userId'),
                                        );
                                      } catch (e) {
                                        print('Error creating complaint: $e');
                                      }
                                      Navigator.pop(context);
                                      _showResponseBottomSheet(
                                          context, result['complainer_view']);

                                      setState(() {
                                        _problemController.clear();
                                        _selectedImage = null;
                                      });
                                    } catch (e) {
                                      // Hide loading indicator
                                      Navigator.pop(context);
                                      _showErrorSnackBar(context,
                                          'Error submitting complaint');
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3A59D1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          screenWidth * 0.02),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.015,
                                      horizontal: screenWidth * 0.1,
                                    ),
                                  ),
                                  child: Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.05,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.05),
                                ElevatedButton(
                                    onPressed: () {
                                      _showImagePickerOptions();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF3A59D1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            screenWidth * 0.02),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: screenHeight * 0.02,
                                        horizontal: screenWidth * 0.05,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.attach_file,
                                      color: Colors.white,
                                      size: screenWidth * 0.05,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.home_rounded,
                              color: Colors.white, size: screenWidth * 0.1)),
                      SizedBox(width: screenWidth * 0.05),
                      IconButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Posts(),
                              ),
                            );
                          },
                          icon: Icon(Icons.feed_rounded,
                              color: Colors.white, size: screenWidth * 0.1)),
                      SizedBox(width: screenWidth * 0.05),
                    ],
                  )
                ],
              ),
            )
          ],
        ));
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _showResponseBottomSheet(BuildContext context, String response) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    // Parse the response text to extract relevant parts
    Map<String, String> parsedData = _parseResponse(response);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.assignment_turned_in,
                                color: Color(0xFF3A59D1),
                                size: screenWidth * 0.06),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'Complaint Registered',
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A59D1),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(height: screenHeight * 0.02, thickness: 2),

                    // Original Complaint
                    _buildSectionWithIcon(
                      Icons.description,
                      'Complaint',
                      parsedData['Original Complaint'] ?? 'Not available',
                    ),

                    // Location
                    _buildSectionWithIcon(
                      Icons.location_on,
                      'Location',
                      parsedData['Location'] ?? 'Not available',
                    ),

                    // Departments Forwarded
                    _buildSectionWithIcon(
                      Icons.forward_to_inbox,
                      'Departments Forwarded',
                      parsedData['Departments Forwarded'] ?? 'Not available',
                    ),

                    // Contact Details
                    if (parsedData['Contact Details'] != null)
                      _buildContactDetails(parsedData['Contact Details']!),

                    // Suggestions
                    if (parsedData['Suggestions'] != null)
                      _buildSuggestionsList(parsedData['Suggestions']!),

                    SizedBox(height: screenHeight * 0.02),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3A59D1),
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1,
                              vertical: screenHeight * 0.015),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionWithIcon(IconData icon, String title, String content,
      {bool includeBottomDivider = true}) {
    // If content is empty, show a placeholder message
    String displayContent =
        content.isEmpty ? 'Information not available' : content;

    // Format timestamp if the section is a timestamp

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF3A59D1), size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 8, bottom: 16),
          child: Text(
            displayContent,
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
        if (includeBottomDivider) Divider(height: 8),
        SizedBox(height: 8),
      ],
    );
  }

  // Format ISO timestamp to human readable format

  // Helper method to get month name from month number

  Widget _buildContactDetails(String contactDetails) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.contact_phone, color: Color(0xFF3A59D1), size: 20),
            SizedBox(width: 8),
            Text(
              'Contact Details',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 8, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: contactDetails.split('\n').map((line) {
              if (line.trim().isEmpty) return SizedBox.shrink();

              if (line.contains('Phone')) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(line.trim(),
                              style: TextStyle(fontSize: 16))),
                    ],
                  ),
                );
              } else if (line.contains('Email')) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.email, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(line.trim(),
                              style: TextStyle(fontSize: 16))),
                    ],
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(line.trim(),
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                );
              }
            }).toList(),
          ),
        ),
        Divider(height: 8),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSuggestionsList(String suggestions) {
    List<String> suggestionItems = [];
    bool collectingItems = false;

    for (String line in suggestions.split('\n')) {
      String trimmedLine = line.trim();
      if (trimmedLine.startsWith('*')) {
        collectingItems = true;
        suggestionItems.add(trimmedLine.substring(1).trim());
      } else if (collectingItems &&
          trimmedLine.isNotEmpty &&
          !trimmedLine.startsWith('-')) {
        // If we were collecting items and got a non-bullet line, add it to the last item
        if (suggestionItems.isNotEmpty) {
          suggestionItems[suggestionItems.length - 1] += ' ' + trimmedLine;
        }
      } else if (trimmedLine.startsWith('-') && trimmedLine.contains('*')) {
        // Extract bullet points from lines starting with dash
        String bulletContent =
            trimmedLine.substring(trimmedLine.indexOf('*')).trim();
        if (bulletContent.isNotEmpty) {
          suggestionItems.add(bulletContent.substring(1).trim());
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Color(0xFF3A59D1), size: 20),
            SizedBox(width: 8),
            Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 8, bottom: 8),
          child: Text(
            suggestions.split('\n').first.replaceAll('- ', '').trim(),
            style: TextStyle(fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: suggestionItems
                .map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        if (suggestions.contains('In the meantime'))
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestions
                        .split('\n')
                        .where((line) => line.contains('In the meantime'))
                        .first
                        .trim(),
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        Divider(height: 8),
        SizedBox(height: 8),
      ],
    );
  }

  Map<String, String> _parseResponse(String response) {
    Map<String, String> result = {};

    // Initialize variables to store current section and its content
    String currentSection = '';
    String currentContent = '';
    List<String> lines = response.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      // Officer view specific format parsing
      if (line.startsWith('Severity:')) {
        result['Severity'] = line.substring('Severity:'.length).trim();
      } else if (line.contains('Summary:')) {
        String summaryText =
            line.substring(line.indexOf('Summary:') + 'Summary:'.length).trim();
        // Remove quotes if present
        if (summaryText.startsWith('"') && summaryText.contains('"')) {
          summaryText = summaryText.substring(1, summaryText.lastIndexOf('"'));
        }
        result['Summary'] = summaryText;
      } else if (line.startsWith('Status:')) {
        result['Status'] = line.substring('Status:'.length).trim();
      } else if (line.startsWith('Departments:')) {
        result['Departments'] = line.substring('Departments:'.length).trim();
      }

      // Complainer view specific format parsing
      else if (line.startsWith('Original Complaint:')) {
        if (currentSection.isNotEmpty) {
          result[currentSection] = currentContent.trim();
        }
        currentSection = 'Original Complaint';
        currentContent = line.substring('Original Complaint:'.length).trim();
      } else if (line.startsWith('Location:')) {
        if (currentSection.isNotEmpty) {
          result[currentSection] = currentContent.trim();
        }
        currentSection = 'Location';
        currentContent = line.substring('Location:'.length).trim();
      } else if (line.startsWith('Departments Forwarded:')) {
        if (currentSection.isNotEmpty) {
          result[currentSection] = currentContent.trim();
        }
        currentSection = 'Departments Forwarded';
        currentContent = line.substring('Departments Forwarded:'.length).trim();
      } else if (line.startsWith('Contact Details:')) {
        if (currentSection.isNotEmpty) {
          result[currentSection] = currentContent.trim();
        }
        currentSection = 'Contact Details';
        currentContent = '';
      } else if (line.startsWith('Suggestions:')) {
        if (currentSection.isNotEmpty) {
          result[currentSection] = currentContent.trim();
        }
        currentSection = 'Suggestions';
        currentContent = '';
      } else if (line.startsWith('Timestamp:')) {
        if (currentSection.isNotEmpty) {
          result[currentSection] = currentContent.trim();
        }
        currentSection = 'Timestamp';
        currentContent = line.substring('Timestamp:'.length).trim();

        // Store timestamp in result directly too
        result['Timestamp'] = line.substring('Timestamp:'.length).trim();
      } else if (currentSection.isNotEmpty) {
        // Add to current section
        currentContent += (currentContent.isEmpty ? '' : '\n') + line;
      }
    }

    // Add the last section
    if (currentSection.isNotEmpty) {
      result[currentSection] = currentContent.trim();
    }

    return result;
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
