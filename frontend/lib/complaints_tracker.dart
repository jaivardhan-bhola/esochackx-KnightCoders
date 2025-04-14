import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:civicsense/services/complaintsApiService.dart';
import 'package:intl/intl.dart';

class ComplaintsTracker extends StatefulWidget {
  const ComplaintsTracker({Key? key}) : super(key: key);

  @override
  State<ComplaintsTracker> createState() => _ComplaintsTrackerState();
}

class _ComplaintsTrackerState extends State<ComplaintsTracker> {
  List<dynamic> complaints = [];
  bool isLoading = true;
  String? errorMessage;
  var box = Hive.box('appBox');
  late int userId;

  @override
  void initState() {
    super.initState();
    userId = int.parse(box.get('userId').toString());
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedComplaints =
          await ComplaintsApiService.getComplaintsByUserId(userId);
      print(fetchedComplaints[0]);
      setState(() {
        complaints = fetchedComplaints;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load complaints: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Method to get the color based on complaint severity
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

  // Method to get the color based on complaint status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  // Method to get the icon based on complaint status
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'in progress':
        return Icons.engineering;
      case 'resolved':
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // Format the date for display
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: Text(
          'My Complaints',
          style: GoogleFonts.instrumentSans(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
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
          ),
          Column(
            children: [
              SizedBox(height: screenHeight * 0.12),
              Expanded(
                child: Container(
                  width: screenWidth,
                  height: screenHeight * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.05),
                      topRight: Radius.circular(screenWidth * 0.05),
                    ),
                  ),
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 48, color: Colors.red),
                                  SizedBox(height: 16),
                                  Text(
                                    errorMessage!,
                                    style: TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _fetchComplaints,
                                    child: Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF3A59D1),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : complaints.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inbox,
                                          size: 64, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'No complaints found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'You haven\'t submitted any complaints yet',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchComplaints,
                                  child: ListView.builder(
                                    padding: EdgeInsets.all(screenWidth * 0.04),
                                    itemCount: complaints.length,
                                    itemBuilder: (context, index) {
                                      final complaint = complaints[index];
                                      final status =
                                          complaint['complaintStatus'] ??
                                              'Unknown';
                                      final severity =
                                          complaint['complaintSeverity'] ?? 0;
                                      final createdAt = complaint['createdAt'];

                                      return Card(
                                        elevation: 4,
                                        margin: EdgeInsets.only(bottom: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          side: BorderSide(
                                            color: Color(0xFF3A59D1)
                                                .withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            _showComplaintDetails(
                                                complaints[index]);
                                          },
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white,
                                                  Color(0xFFF5F7FF)
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            horizontal: 10,
                                                            vertical: 6,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                _getStatusColor(
                                                                        status)
                                                                    .withOpacity(
                                                                        0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                _getStatusIcon(
                                                                    status),
                                                                size: 16,
                                                                color:
                                                                    _getStatusColor(
                                                                        status),
                                                              ),
                                                              SizedBox(
                                                                  width: 6),
                                                              Flexible(
                                                                child: Text(
                                                                  status,
                                                                  style: GoogleFonts
                                                                      .instrumentSans(
                                                                    color: _getStatusColor(
                                                                        status),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal: 8,
                                                          vertical: 6,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              _getSeverityColor(
                                                                      severity)
                                                                  .withOpacity(
                                                                      0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                        ),
                                                        child: Text(
                                                          'Severity: $severity',
                                                          style: GoogleFonts
                                                              .instrumentSans(
                                                            color:
                                                                _getSeverityColor(
                                                                    severity),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 14),
                                                  Text(
                                                    complaint[
                                                            'summarisedText'] ??
                                                        'No summary available',
                                                    style: GoogleFonts
                                                        .instrumentSans(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF3A59D1),
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    complaint['longText'] ??
                                                        'No description provided',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 12),
                                                  Divider(
                                                    color: Colors.grey
                                                        .withOpacity(0.2),
                                                    height: 1,
                                                  ),
                                                  SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            EdgeInsets.all(6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Color(
                                                                  0xFF3A59D1)
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .location_on_outlined,
                                                          size: 16,
                                                          color:
                                                              Color(0xFF3A59D1),
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          complaint[
                                                                  'Location'] ??
                                                              'Unknown location',
                                                          style: GoogleFonts
                                                              .instrumentSans(
                                                            color: Colors
                                                                .grey[700],
                                                            fontSize: 13,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
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
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(6),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .green
                                                                    .withOpacity(
                                                                        0.1),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              child: Icon(
                                                                Icons.business,
                                                                size: 16,
                                                                color: Colors
                                                                    .green[700],
                                                              ),
                                                            ),
                                                            SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                'Dept: ${complaint['Department'] ?? 'Unknown'}',
                                                                style: GoogleFonts
                                                                    .instrumentSans(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                          .grey[
                                                                      700],
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            EdgeInsets.all(6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.amber
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .calendar_today_outlined,
                                                              size: 14,
                                                              color: Colors
                                                                  .amber[700],
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              _formatDate(
                                                                  createdAt),
                                                              style: GoogleFonts
                                                                  .instrumentSans(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .amber[700],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
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

  void _showComplaintDetails(dynamic complaint) {
    final attributes = complaint;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

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
                        color: _getSeverityColor(
                                attributes['complaintSeverity'] ?? 0)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getSeverityColor(
                              attributes['complaintSeverity'] ?? 0),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Severity: ${attributes['complaintSeverity'] ?? 'Unknown'}',
                        style: TextStyle(
                          color: _getSeverityColor(
                              attributes['complaintSeverity'] ?? 0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _detailRow('Status', attributes['complaintStatus'] ?? 'Unknown',
                    valueColor: _getStatusColor(
                        attributes['complaintStatus'] ?? 'Unknown')),
                _detailRow('Department', attributes['Department'] ?? 'Unknown'),
                _detailRow('Location', attributes['Location'] ?? 'Unknown'),
                _detailRow(
                    'Submitted on', _formatDate(attributes['createdAt'])),
                _detailRow(
                    'Last updated', _formatDate(attributes['updatedAt'])),
                Divider(height: screenHeight * 0.03, thickness: 1),
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
                if (attributes['imageAnalysis'] != null &&
                    attributes['imageAnalysis'].toString().isNotEmpty &&
                    attributes['imageAnalysis'] != "null") ...[
                  SizedBox(height: 16),
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
                            attributes['imageAnalysis'],
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3A59D1),
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        color: Colors.white,
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
}
