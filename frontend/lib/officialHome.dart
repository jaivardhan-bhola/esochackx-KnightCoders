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
                    height: screenHeight * 0.818,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                                          () => setState(
                                              () => filterStatus = 'Pending'),
                                          Colors.orange,
                                        ),
                                        SizedBox(width: 10),
                                        FilterChip(
                                          'Completed',
                                          filterStatus == 'Completed',
                                          () => setState(
                                              () => filterStatus = 'Completed'),
                                          Colors.green,
                                        ),
                                        SizedBox(width: 10),
                                        FilterChip(
                                          'Rejected',
                                          filterStatus == 'Rejected',
                                          () => setState(
                                              () => filterStatus = 'Rejected'),
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
                                        .map((complaint) => buildComplaintCard(
                                            complaint,
                                            screenWidth,
                                            screenHeight))
                                        .toList(),
                                  ),
                              ])),
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
                      IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Chatbot(),
                              ),
                            );
                          },
                          icon: Icon(Icons.chat_rounded,
                              color: Colors.white, size: screenWidth * 0.1)),
                    ],
                  )
                ],
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            fetchComplaints();
          },
          backgroundColor: Color(0xFF3A59D1),
          child: Icon(Icons.refresh, color: Colors.white),
        ));
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
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: getStatusColor(status),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        leading: getStatusIcon(status),
        title: Text(
          summary,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.04,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                location,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: screenWidth * 0.035),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complaint Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.045,
                    color: Color(0xFF3A59D1),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  longText,
                  style: TextStyle(fontSize: screenWidth * 0.035),
                  softWrap: true,
                ),

                // Display complaint image if available
                if (images != null && images.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Attached Image:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                      color: Color(0xFF3A59D1),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: screenHeight * 0.2,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final image = images![index];
                        String? imageUrl;
                        imageUrl = image['formats']['small']['url'] ??
                            image['formats']['thumbnail']['url'] ??
                            image['formats']['large']['url'] ??
                            image['formats']['medium']['url'];
                        imageUrl =
                             'http://${DotEnv.dotenv.env['HOST']}:${DotEnv.dotenv.env['PORT']}${imageUrl}'; // Use the server URL from .env
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: screenWidth * 0.4,
                                  height: screenHeight * 0.2,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress
                                                  .expectedTotalBytes !=
                                              null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              (loadingProgress
                                                      .expectedTotalBytes ??
                                                  1)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return Container(
                                  width: screenWidth * 0.4,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(Icons.broken_image, size: 40),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      
                      },
                    ),
                  ),
                ],

                SizedBox(height: 16),
                // Department row
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Department:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        department,
                        style: TextStyle(color: Colors.black),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                // Severity row
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Severity:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        severity,
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
                // Status row
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        status,
                        style: TextStyle(color: getStatusColor(status)),
                      ),
                    ],
                  ),
                ),
                // Date row
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        createdAt,
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.update, size: 16),
                    label: Text('Update Status'),
                    onPressed: () {
                      // Pass the documentId to the update dialog
                      showStatusUpdateDialog(documentId, status);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF3A59D1),
                    ),
                  ),
                ),
              ],
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
      builder: (context) => AlertDialog(
        title: Text('Update Complaint Status'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text('Pending'),
                  value: 'Pending',
                  groupValue: newStatus,
                  onChanged: (value) {
                    setState(() {
                      newStatus = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text('Completed'),
                  value: 'Completed',
                  groupValue: newStatus,
                  onChanged: (value) {
                    setState(() {
                      newStatus = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text('Rejected'),
                  value: 'Rejected',
                  groupValue: newStatus,
                  onChanged: (value) {
                    setState(() {
                      newStatus = value!;
                    });
                  },
                ),
              ],
            );
          },
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
                  SnackBar(content: Text('Status updated successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update status')),
                );
              }
            },
            child: Text('Update'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF3A59D1),
            ),
          ),
        ],
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
