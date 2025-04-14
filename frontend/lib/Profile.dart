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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
                CircleAvatar(
                  radius: screenWidth * 0.15,
                  backgroundColor: Colors.white,
                  child: Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text[0].toUpperCase()
                        : "U",
                    style: TextStyle(
                      fontSize: screenWidth * 0.15,
                      color: Color(0xFF3A59D1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  _nameController.text,
                  style: GoogleFonts.instrumentSans(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  userType,
                  style: GoogleFonts.instrumentSans(
                    fontSize: screenWidth * 0.04,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
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
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isChangingPassword) ...[
                            Text(
                              _isEditing
                                  ? "Edit Profile"
                                  : "Profile Information",
                              style: GoogleFonts.instrumentSans(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A59D1),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),

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

                            if (_isEditing) ...[
                              SizedBox(height: screenHeight * 0.03),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: _updateProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF3A59D1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.1,
                                        vertical: screenHeight * 0.015,
                                      ),
                                    ),
                                    child: Text(
                                      'Save Changes',
                                      style: GoogleFonts.instrumentSans(
                                        fontSize: screenWidth * 0.045,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            SizedBox(height: screenHeight * 0.03),
                            Divider(),
                            SizedBox(height: screenHeight * 0.02),

                            // Actions
                            if (!_isEditing) ...[
                              if (userType == "Citizen") ...[
                                _buildActionTile(
                                  icon: Icons.report_problem,
                                  title: "Track Complaints",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ComplaintsTracker()),
                                    );
                                  },
                                ),
                              ],
                              _buildActionTile(
                                icon: Icons.lock,
                                title: "Change Password",
                                onTap: () {
                                  setState(() {
                                    _isChangingPassword = true;
                                  });
                                },
                              ),
                              _buildActionTile(
                                icon: Icons.help_outline,
                                title: "Help & Support",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Chatbot()),
                                  );
                                },
                              ),
                              _buildActionTile(
                                icon: Icons.logout,
                                title: "Logout",
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Confirm Logout"),
                                        content: Text(
                                            "Are you sure you want to logout?"),
                                        actions: [
                                          TextButton(
                                            child: Text("Cancel"),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                          TextButton(
                                            child: Text("Logout"),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _logout();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                textColor: Colors.red,
                              ),
                            ],
                          ],

                          // Password Change Form
                          if (_isChangingPassword) ...[
                            Text(
                              "Change Password",
                              style: GoogleFonts.instrumentSans(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A59D1),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: _changePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3A59D1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.1,
                                      vertical: screenHeight * 0.015,
                                    ),
                                  ),
                                  child: Text(
                                    'Update Password',
                                    style: GoogleFonts.instrumentSans(
                                      fontSize: screenWidth * 0.045,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
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

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditable,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF3A59D1)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    controller.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: Color(0xFF3A59D1)),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintText: label,
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
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
        style: TextStyle(
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
