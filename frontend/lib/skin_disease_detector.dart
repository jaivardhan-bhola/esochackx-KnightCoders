import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'MLApiCalls.dart';

class SkinDiseaseDetector extends StatefulWidget {
  const SkinDiseaseDetector({Key? key}) : super(key: key);

  @override
  State<SkinDiseaseDetector> createState() => _SkinDiseaseDetectorState();
}

class _SkinDiseaseDetectorState extends State<SkinDiseaseDetector> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _prediction;
  double? _confidence;
  String? _errorMessage;
  
  // Add variables to store health information
  String? _symptoms;
  String? _treatment;
  String? _prevention;

  // ML API Service instance
  final _mlApiService = MLApiService();

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _prediction = null;
          _confidence = null;
          _errorMessage = null;
          _symptoms = null;
          _treatment = null;
          _prevention = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  // Show image picker options (camera or gallery)
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
                  _getImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _predictSkinDisease() async {
    if (_imageFile == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _mlApiService.predictSkinDisease(_imageFile!);

      setState(() {
        _prediction = result['prediction'] as String;
        _confidence = result['confidence'] as double;
        // Store the additional health information
        _symptoms = result['symptoms'] as String?;
        _treatment = result['treatment'] as String?;
        _prevention = result['prevention'] as String?;
        _isLoading = false;
      });
      
      if (_prediction != null) {
        _showResultsBottomSheet(context);
      }
      
    } catch (e) {
      setState(() {
        // More user-friendly error message
        if (e.toString().contains('Skin disease model not loaded')) {
          _errorMessage =
              'The skin disease detection service is currently unavailable. Please try again later.';
        } else {
          _errorMessage =
              'Analysis failed: ${e.toString().replaceAll('Exception: ', '')}';
        }
        _isLoading = false;
      });

      // Log detailed error for debugging
      print('Error in skin disease prediction: $e');
    }
  }

  void _showResultsBottomSheet(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

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
                            Icon(Icons.medical_services_rounded,
                                color: Color(0xFF3A59D1),
                                size: screenWidth * 0.06),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'Diagnosis Results',
                              style: GoogleFonts.instrumentSans(
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

                    // Detected Condition
                    _buildSectionWithIcon(
                      context,
                      Icons.coronavirus,
                      'Detected Condition',
                      _prediction ?? 'Unknown',
                      confidence: _confidence,
                    ),

                    // Symptoms
                    if (_symptoms != null)
                      _buildSectionWithIcon(
                        context,
                        Icons.sick_outlined,
                        'Symptoms',
                        _symptoms!,
                      ),

                    // Treatment
                    if (_treatment != null)
                      _buildSectionWithIcon(
                        context,
                        Icons.medical_services_outlined,
                        'Treatment Options',
                        _treatment!,
                      ),

                    // Prevention
                    if (_prevention != null)
                      _buildSectionWithIcon(
                        context,
                        Icons.health_and_safety_outlined,
                        'Prevention Methods',
                        _prevention!,
                      ),

                    SizedBox(height: screenHeight * 0.02),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This is an AI-assisted prediction and should not replace professional medical advice. Please consult a dermatologist for proper diagnosis.',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.red.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

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
                          style: GoogleFonts.instrumentSans(
                            fontSize: 16, 
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildSectionWithIcon(BuildContext context, IconData icon, String title, String content, {double? confidence}) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF3A59D1), size: screenWidth * 0.05),
            SizedBox(width: screenWidth * 0.02),
            Text(
              title,
              style: GoogleFonts.instrumentSans(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
            left: screenWidth * 0.07, 
            top: screenWidth * 0.02, 
            bottom: screenWidth * 0.01
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: title == 'Detected Condition' ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (confidence != null) 
                Padding(
                  padding: EdgeInsets.only(top: screenWidth * 0.01),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenWidth * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF3A59D1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    ),
                    child: Text(
                      'Confidence Level: ${(confidence * 100).toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3A59D1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Divider(height: screenWidth * 0.04, thickness: 1),
        SizedBox(height: screenWidth * 0.01),
      ],
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
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: screenWidth * 0.05,
              backgroundImage: AssetImage('assets/logo.png'),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'Skin Disease Detector',
              style: GoogleFonts.instrumentSans(
                fontSize: screenWidth * 0.05,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
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
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top spacing for app bar
              SizedBox(height: screenHeight * 0.12),
              
              // Image preview area
              Container(
                width: screenWidth * 0.8,
                height: screenHeight * 0.3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _imageFile != null 
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 60,
                            color: Color(0xFF3A59D1).withOpacity(0.5),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Upload a skin image',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                ),
              ),
              
              SizedBox(height: screenHeight * 0.02),
              
              // White container for rest of UI
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.05),
                      topRight: Radius.circular(screenWidth * 0.05),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructions',
                            style: GoogleFonts.instrumentSans(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Take a clear photo of the affected skin area for analysis.',
                            style: TextStyle(fontSize: screenWidth * 0.035),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Error message
                          if (_errorMessage != null)
                            Container(
                              padding: EdgeInsets.all(10),
                              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Upload Image button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showImagePickerOptions,
                                  icon: Icon(Icons.photo_library),
                                  label: Text('Upload Image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3A59D1),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              // Analyze button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _predictSkinDisease,
                                  icon: _isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(Icons.search),
                                  label: Text(_isLoading ? 'Analyzing...' : 'Analyze'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF71B340),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Info box (always shown)
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About Skin Analysis',
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'This tool uses AI to analyze skin conditions and provide information about potential diseases. The analysis includes:',
                                  style: TextStyle(fontSize: screenWidth * 0.035),
                                ),
                                SizedBox(height: 8),
                                _infoRow(Icons.coronavirus_outlined, 'Disease identification'),
                                _infoRow(Icons.sick_outlined, 'Symptoms information'),
                                _infoRow(Icons.medical_services_outlined, 'Treatment options'),
                                _infoRow(Icons.health_and_safety_outlined, 'Prevention methods'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFF3A59D1)),
          SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
