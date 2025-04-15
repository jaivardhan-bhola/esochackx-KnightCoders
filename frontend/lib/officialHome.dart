import 'package:civicsense/Posts.dart';
import 'package:civicsense/Profile.dart';
import 'package:civicsense/chatbot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:civicsense/services/complaintsApiService.dart'; // Import the complaints service
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:civicsense/widgets/parallelogram_shape.dart'; // Import the custom shape

class Officialhome extends StatefulWidget {
  const Officialhome({super.key});

  @override
  State<Officialhome> createState() => _OfficialhomeState();
}

class _OfficialhomeState extends State<Officialhome> {
  List<dynamic> complaints = [];
  bool isLoading = true;
  String filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedComplaints = await ComplaintsApiService.getComplaints();

      setState(() {
        complaints = fetchedComplaints;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching complaints: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Icon getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icon(Icons.watch_later, color: Colors.orange);
      case 'completed':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'rejected':
        return Icon(Icons.cancel, color: Colors.red);
      default:
        return Icon(Icons.help, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          forceMaterialTransparency: true,
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
                  SizedBox(height: screenHeight * 0.12),
                  Container(
                    width: screenWidth,
                    height: screenHeight * 0.815,
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: RefreshIndicator(
                      onRefresh: fetchComplaints,
                      color: Color(0xFF3A59D1),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
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
                                    'Complaints Dashboard',
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3A59D1),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Container(
                                    height: screenHeight * 0.05,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          FilterChip(
                                            'All',
                                            filterStatus == 'All',
                                            () => setState(
                                                () => filterStatus = 'All'),
                                            Colors.grey,
                                          ),
                                          SizedBox(width: 10),
                                          FilterChip(
                                            'Pending',
                                            filterStatus == 'Pending',
                                            () => setState(() =>
                                                filterStatus == 'Pending'),
                                            Colors.orange,
                                          ),
                                          SizedBox(width: 10),
                                          FilterChip(
                                            'Completed',
                                            filterStatus == 'Completed',
                                            () => setState(() =>
                                                filterStatus = 'Completed'),
                                            Colors.green,
                                          ),
                                          SizedBox(width: 10),
                                          FilterChip(
                                            'Rejected',
                                            filterStatus == 'Rejected',
                                            () => setState(() =>
                                                filterStatus = 'Rejected'),
                                            Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  if (isLoading)
                                    Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  else if (complaints.isEmpty)
                                    Center(
                                      child: Text(
                                        'No complaints found',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  else
                                    Column(
                                      children: complaints
                                          .where((complaint) {
                                            final attributes =
                                                complaint['attributes'] ??
                                                    complaint;
                                            final status =
                                                attributes['complaintStatus'] ??
                                                    '';
                                            return filterStatus == 'All' ||
                                                status.toLowerCase() ==
                                                    filterStatus.toLowerCase();
                                          })
                                          .map((complaint) =>
                                              buildComplaintCard(complaint,
                                                  screenWidth, screenHeight))
                                          .toList(),
                                    ),
                                ])),
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
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF3A59D1)),
                  ),
                ),
              ),
          ],
        ),
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
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat);
  }

  Widget FilterChip(
      String label, bool isSelected, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildComplaintCard(
      dynamic complaint, double screenWidth, double screenHeight) {
    // Handle both nested and flat data structure
    final attributes = complaint['attributes'] ?? complaint;

    // This is the document ID that should be used for API calls
    final documentId = complaint['documentId']?.toString() ?? '';

    final summary = attributes['summarisedText'] ?? 'No summary available';
    final longText = attributes['longText'] ?? 'No details available';
    final status = attributes['complaintStatus'] ?? 'Unknown';
    final severity = attributes['complaintSeverity']?.toString() ?? '0';
    final department = attributes['Department'] ?? 'Unknown department';
    final location = attributes['Location'] ?? 'Unknown location';
    final imageValidation = attributes['imageValidation'] ?? '';
    final officialResponse = attributes['officialResponse'] ?? '';

    // Handle image data
    List<dynamic>? images;
    if (attributes['image'] != null) {
      // Make sure we're treating 'image' as a list of objects rather than trying to cast it
      images = attributes['image'] as List<dynamic>;
    }

    // Parse the date from createdAt
    DateTime? createdDate;
    try {
      if (attributes['createdAt'] != null) {
        createdDate = DateTime.parse(attributes['createdAt']);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    final createdAt = createdDate != null
        ? DateFormat('MMM d, yyyy').format(createdDate)
        : 'Unknown date';

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: Color(0xFF3A59D1).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Show the expanded complaint details when tapped
          _showComplaintDetails(complaint, documentId);
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF5F7FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              status.toLowerCase() == 'pending'
                                  ? Icons.pending
                                  : status.toLowerCase() == 'completed'
                                      ? Icons.check_circle
                                      : status.toLowerCase() == 'rejected'
                                          ? Icons.cancel
                                          : Icons.help_outline,
                              size: 16,
                              color: getStatusColor(status),
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                status,
                                style: GoogleFonts.instrumentSans(
                                  color: getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(int.tryParse(severity) ?? 0)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Severity: $severity',
                        style: GoogleFonts.instrumentSans(
                          color: _getSeverityColor(int.tryParse(severity) ?? 0),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Text(
                  summary,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A59D1),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  longText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Divider(
                  color: Colors.grey.withOpacity(0.2),
                  height: 1,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xFF3A59D1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFF3A59D1),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.instrumentSans(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.business,
                              size: 16,
                              color: Colors.green[700],
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dept: $department',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.amber[700],
                          ),
                          SizedBox(width: 4),
                          Text(
                            createdAt,
                            style: GoogleFonts.instrumentSans(
                              fontSize: 12,
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.update, size: 16, color: Colors.white),
                    label: Text('Update Status'),
                    onPressed: () {
                      // Pass the documentId to the update dialog
                      showStatusUpdateDialog(documentId, status);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF3A59D1),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for severity color
  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
      case 2:
        return Colors.amber; // Yellow for severity 1-2
      case 3:
      case 4:
        return Colors.orange; // Orange for severity 3-4
      case 5:
        return Colors.red; // Red for severity 5
      default:
        return Colors.grey;
    }
  }

  // Format date helper method
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showComplaintDetails(dynamic complaint, String documentId) {
    final attributes = complaint['attributes'] ?? complaint;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    final status = attributes['complaintStatus'] ?? 'Unknown';
    final severity = attributes['complaintSeverity'] ?? 0;

    // Handle image data
    List<dynamic>? images;
    String? imageUrl;
    if (attributes['image'] != null &&
        attributes['image'] is List &&
        (attributes['image'] as List).isNotEmpty) {
      images = attributes['image'] as List<dynamic>;
      if (images.isNotEmpty && images[0]['url'] != null) {
        String rawUrl = images[0]['formats']['thumbnail']['url'];
        print(
            '${DotEnv.dotenv.env['HOST']}:${DotEnv.dotenv.env['PORT']}$rawUrl');
        imageUrl =
            'http://${DotEnv.dotenv.env['HOST']}:${DotEnv.dotenv.env['PORT']}$rawUrl';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    margin: EdgeInsets.only(bottom: 20),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Complaint Details',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A59D1),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(severity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getSeverityColor(severity),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Severity: ${severity}',
                        style: TextStyle(
                          color: _getSeverityColor(severity),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _detailRow('Status', status,
                    valueColor: getStatusColor(status)),
                _detailRow('Department', attributes['Department'] ?? 'Unknown'),
                _detailRow('Location', attributes['Location'] ?? 'Unknown'),
                _detailRow(
                    'Submitted on', _formatDate(attributes['createdAt'])),
                _detailRow(
                    'Last updated', _formatDate(attributes['updatedAt'])),
                Divider(height: screenHeight * 0.03, thickness: 1),

                // Display complaint image if available
                if (imageUrl != null) ...[
                  Text(
                    'Image',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A59D1),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, color: Colors.red),
                                SizedBox(height: 8),
                                Text('Failed to load image'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Display image analysis right after the image
                if (attributes['imageValidation'] != null &&
                    attributes['imageValidation'].toString().isNotEmpty &&
                    attributes['imageValidation'] != "null") ...[
                  Text(
                    'Image Analysis',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A59D1),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.shade300,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.image_search, color: Colors.amber.shade700),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            attributes['imageValidation'],
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                Text(
                  'Summary',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A59D1),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF3A59D1).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    attributes['summarisedText'] ?? 'No summary available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                SizedBox(height: 16),
                Text(
                  'Description',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A59D1),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  attributes['longText'] ?? 'No description provided',
                  style: TextStyle(fontSize: 16),
                ),

                if (attributes['officialResponse'] != null &&
                    attributes['officialResponse'].toString().isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Official Response',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A59D1),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF3A59D1).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xFF3A59D1).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      attributes['officialResponse'],
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],

                SizedBox(height: 30),
                // Only showing the Update Status button, removed Add Response button
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.update, size: 18, color: Colors.white),
                    label: Text('Update Status'),
                    onPressed: () {
                      Navigator.pop(context);
                      showStatusUpdateDialog(documentId, status);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF3A59D1),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Close',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showStatusUpdateDialog(String complaintId, String currentStatus) {
    String newStatus = currentStatus;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF5F7FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.update, color: Color(0xFF3A59D1)),
                  SizedBox(width: 10),
                  Text(
                    'Update Complaint Status',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A59D1),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    children: [
                      _buildStatusOption(
                        'Pending',
                        'pending',
                        Colors.orange,
                        newStatus,
                        (value) => setState(() => newStatus = value),
                      ),
                      SizedBox(height: 10),
                      _buildStatusOption(
                        'Completed',
                        'completed',
                        Colors.green,
                        newStatus,
                        (value) => setState(() => newStatus = value),
                      ),
                      SizedBox(height: 10),
                      _buildStatusOption(
                        'Rejected',
                        'rejected',
                        Colors.red,
                        newStatus,
                        (value) => setState(() => newStatus = value),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();

                      // Show loading indicator
                      setState(() {
                        isLoading = true;
                      });

                      // Update the complaint status
                      bool success = await ComplaintsApiService.updateComplaint(
                        id: complaintId,
                        complaintStatus: newStatus,
                      );

                      // Refresh the complaints list regardless of success/failure
                      await fetchComplaints();

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Status updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update status'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF3A59D1),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Update',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    String label,
    String value,
    Color color,
    String groupValue,
    Function(String) onChanged,
  ) {
    final isSelected = groupValue.toLowerCase() == value.toLowerCase();

    return InkWell(
      onTap: () => onChanged(label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.black,
              ),
            ),
            Spacer(),
            Icon(
              value.toLowerCase() == 'pending'
                  ? Icons.pending
                  : value.toLowerCase() == 'completed'
                      ? Icons.check_circle
                      : value.toLowerCase() == 'rejected'
                          ? Icons.cancel
                          : Icons.help_outline,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void showResponseDialog(String complaintId) {
    final responseController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Respond to Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: responseController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter your response...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Update the complaint with official response
              bool success = await ComplaintsApiService.updateComplaint(
                id: complaintId,
                officialResponse: responseController.text,
                // Optional: update status to In Progress if needed
                complaintStatus: 'In Progress',
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Response submitted successfully')),
                );
                fetchComplaints(); // Refresh the complaints list
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to submit response')),
                );
              }
            },
            child: Text('Submit'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
