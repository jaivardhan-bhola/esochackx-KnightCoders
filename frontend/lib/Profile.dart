import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:civicsense/Login.dart';
import 'package:civicsense/Home.dart';
import 'package:civicsense/services/userApiService.dart';
import 'package:civicsense/chatbot.dart';
import 'package:civicsense/complaints_tracker.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isEditing = false;
  bool _isChangingPassword = false;
  bool _isPasswordVisible = false;
  late String userId; // Ensuring userId is a string
  late String userType;
  var box = Hive.box('appBox');

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _nameController.text = box.get('name') ?? '';
    _emailController.text = box.get('email') ?? '';
    _phoneController.text = box.get('phone') ?? '';

    // Ensure userId is always a string
    var storedUserId = box.get('userId');
    userId = storedUserId != null ? storedUserId.toString() : '';

    userType = box.get('type') ?? '';
  }

  Future<void> _updateProfile() async {
    // Show loading indicator
    _showLoadingDialog();

    try {
      // Call user update API service
      final response = await UserApiService.updateUserProfile(
        userId,
        _nameController.text,
        _emailController.text,
        _phoneController.text,
      );

      // Update local storage
      box.put('name', _nameController.text);
      box.put('email', _nameController.text);
      box.put('phone', _nameController.text);

      // Hide loading indicator and toggle edit mode
      Navigator.pop(context); // pop loading dialog

      setState(() {
        _isEditing = false;
      });

      _showSnackBar('Profile updated successfully');
    } catch (error) {
      // Hide loading indicator
      Navigator.pop(context);
      _showSnackBar('Failed to update profile: ${error.toString()}');
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      _showSnackBar('Please fill in both password fields');
      return;
    }

    // Show loading indicator
    _showLoadingDialog();

    try {
      // Call password change API service
      await UserApiService.changePassword(
        userId,
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      // Hide loading indicator and toggle password change mode
      Navigator.pop(context);

      setState(() {
        _isChangingPassword = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
      });

      _showSnackBar('Password changed successfully');
    } catch (error) {
      // Hide loading indicator
      Navigator.pop(context);
      _showSnackBar('Failed to change password: ${error.toString()}');
    }
  }

  void _logout() {
    box.put('isLoggedIn', false);
    box.clear();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => Login()),
      (Route<dynamic> route) => false,
    );
  }

  void _showLoadingDialog() {
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF3A59D1),
      ),
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
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.instrumentSans(
            fontSize: screenWidth * 0.06,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        actions: [
          if (!_isEditing && !_isChangingPassword)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing || _isChangingPassword)
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _isChangingPassword = false;
                  _loadUserData(); // Reset fields to original values
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                });
              },
            ),
        ],
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

          // Content
          Column(
            children: [
              // Profile header with avatar
              SizedBox(height: screenHeight * 0.12),
              Container(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                child: Column(
                  children: [
                    // Avatar with animated border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: screenWidth * 0.15,
                        backgroundColor: Colors.white,
                        child: Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : "U",
                          style: GoogleFonts.instrumentSans(
                            fontSize: screenWidth * 0.15,
                            color: Color(0xFF3A59D1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    // User name and type
                    Text(
                      _nameController.text,
                      style: GoogleFonts.instrumentSans(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 6),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userType,
                        style: GoogleFonts.instrumentSans(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Main content area
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.07),
                      topRight: Radius.circular(screenWidth * 0.07),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isChangingPassword) ...[
                          // Section heading
                          Row(
                            children: [
                              Icon(
                                _isEditing
                                    ? Icons.edit_note
                                    : Icons.person_outline,
                                color: Color(0xFF3A59D1),
                                size: screenWidth * 0.07,
                              ),
                              SizedBox(width: 10),
                              Text(
                                _isEditing
                                    ? "Edit Profile"
                                    : "Profile Information",
                                style: GoogleFonts.instrumentSans(
                                  fontSize: screenWidth * 0.055,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3A59D1),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.025),

                          // Profile fields
                          _buildProfileField(
                            icon: Icons.person,
                            label: "Name",
                            controller: _nameController,
                            isEditable: _isEditing,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildProfileField(
                            icon: Icons.email,
                            label: "Email",
                            controller: _emailController,
                            isEditable: _isEditing,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildProfileField(
                            icon: Icons.phone,
                            label: "Phone",
                            controller: _phoneController,
                            isEditable: _isEditing,
                            keyboardType: TextInputType.phone,
                          ),

                          // Save button when editing
                          if (_isEditing) ...[
                            SizedBox(height: screenHeight * 0.03),
                            Center(
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.save, size: 20),
                                label: Text(
                                  'Save Changes',
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onPressed: _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Color(0xFF3A59D1),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.1,
                                    vertical: screenHeight * 0.015,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],

                          // Actions section
                          if (!_isEditing) ...[
                            SizedBox(height: screenHeight * 0.035),
                            Divider(
                              color: Colors.grey.withOpacity(0.3),
                              thickness: 1.5,
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // Section heading for actions
                            Row(
                              children: [
                                Icon(
                                  Icons.settings,
                                  color: Color(0xFF3A59D1),
                                  size: screenWidth * 0.065,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Account Settings",
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: screenWidth * 0.055,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3A59D1),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // Styled action tiles
                            if (userType == "Citizen") ...[
                              _buildStyledActionTile(
                                context: context,
                                icon: Icons.report_problem_outlined,
                                title: "Track Complaints",
                                subtitle:
                                    "View and manage your complaint records",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ComplaintsTracker()),
                                  );
                                },
                                iconBackgroundColor:
                                    Colors.amber.withOpacity(0.15),
                                iconColor: Colors.amber.shade700,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                            ],

                            _buildStyledActionTile(
                              context: context,
                              icon: Icons.lock_outlined,
                              title: "Change Password",
                              subtitle: "Update your account password",
                              onTap: () {
                                setState(() {
                                  _isChangingPassword = true;
                                });
                              },
                              iconBackgroundColor:
                                  Color(0xFF3A59D1).withOpacity(0.15),
                              iconColor: Color(0xFF3A59D1),
                            ),

                            SizedBox(height: screenHeight * 0.015),

                            _buildStyledActionTile(
                              context: context,
                              icon: Icons.help_outline,
                              title: "Help & Support",
                              subtitle: "Get assistance with the app",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Chatbot()),
                                );
                              },
                              iconBackgroundColor:
                                  Colors.green.withOpacity(0.15),
                              iconColor: Colors.green.shade700,
                            ),

                            SizedBox(height: screenHeight * 0.015),

                            _buildStyledActionTile(
                              context: context,
                              icon: Icons.logout,
                              title: "Logout",
                              subtitle: "Sign out from your account",
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 8,
                                      child: Container(
                                        padding: EdgeInsets.all(20),
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
                                              BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.logout,
                                                    color: Colors.red),
                                                SizedBox(width: 10),
                                                Text(
                                                  'Confirm Logout',
                                                  style: GoogleFonts
                                                      .instrumentSans(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 20),
                                            Text(
                                              'Are you sure you want to logout from CivicSense?',
                                              style: GoogleFonts.instrumentSans(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text(
                                                    'Cancel',
                                                    style: GoogleFonts
                                                        .instrumentSans(
                                                      fontSize: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 16),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _logout();
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.white,
                                                    backgroundColor: Colors.red,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 12),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Logout',
                                                    style: GoogleFonts
                                                        .instrumentSans(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              iconBackgroundColor: Colors.red.withOpacity(0.15),
                              iconColor: Colors.red,
                              textColor: Colors.red,
                            ),
                          ],
                        ],

                        // Password Change Form
                        if (_isChangingPassword) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                color: Color(0xFF3A59D1),
                                size: screenWidth * 0.07,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Change Password",
                                style: GoogleFonts.instrumentSans(
                                  fontSize: screenWidth * 0.055,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3A59D1),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          _buildPasswordField(
                            label: "Current Password",
                            controller: _currentPasswordController,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildPasswordField(
                            label: "New Password",
                            controller: _newPasswordController,
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          Center(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.vpn_key, size: 20, color: Colors.white),
                              label: Text(
                                'Update Password',
                                style: GoogleFonts.instrumentSans(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onPressed: _changePassword,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Color(0xFF3A59D1),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.1,
                                  vertical: screenHeight * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  // Updated profile field with more modern design
  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditable,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 0.5,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF3A59D1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Color(0xFF3A59D1),
              size: 22,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.instrumentSans(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isEditable)
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    controller.text,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Updated password field with more modern design
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 0.5,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF3A59D1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lock, color: Color(0xFF3A59D1), size: 22),
          ),
          SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintText: label,
                hintStyle: GoogleFonts.instrumentSans(
                  color: Colors.grey[400],
                ),
              ),
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Color(0xFF3A59D1),
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ],
      ),
    );
  }

  // New modern styled action tile widget
  Widget _buildStyledActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconBackgroundColor,
    required Color iconColor,
    Color? textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            spreadRadius: 0.5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor ?? Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: textColor ?? Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Keep the original _buildActionTile method for backward compatibility
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF3A59D1)),
      title: Text(
        title,
        style: GoogleFonts.instrumentSans(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: textColor,
        ),
      ),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}
