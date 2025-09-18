import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_app/pages/auth_service.dart';
import 'package:project_app/pages/login.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userId;

  const EditProfilePage({super.key, required this.userData, required this.userId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _emailController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isProfileLoading = false;
  bool _isPasswordLoading = false;
  String _profileErrorMessage = '';
  String _passwordErrorMessage = '';
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    print('EditProfilePage - Initialisation avec userData: ${widget.userData}, userId: ${widget.userId}');
    _firstnameController = TextEditingController(text: widget.userData['firstname']);
    _lastnameController = TextEditingController(text: widget.userData['lastname']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _isProfileLoading = true;
      _profileErrorMessage = '';
    });

    try {
      final token = await _authService.getToken();
      print('EditProfilePage - Token (updateProfile): $token');
      if (token == null) {
        throw Exception('Aucun token trouvé. Veuillez vous reconnecter.');
      }

      final updateData = {
        'firstname': _firstnameController.text.trim(),
        'lastname': _lastnameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      final response = await http.patch(
        Uri.parse('http://10.0.2.2:6006/users/updateUser'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );

      print('EditProfilePage - PATCH /users/updateUser Statut: ${response.statusCode}');
      print('EditProfilePage - PATCH /users/updateUser Réponse: ${response.body}');

      if (response.statusCode == 200) {
        final updatedData = json.decode(response.body);
        Navigator.pop(context, {
          'firstname': updatedData['firstname'] ?? _firstnameController.text,
          'lastname': updatedData['lastname'] ?? _lastnameController.text,
          'email': updatedData['email'] ?? _emailController.text,
        });
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _profileErrorMessage = errorData['message'] ?? 'Erreur lors de la mise à jour';
          _isProfileLoading = false;
        });
        if (response.statusCode == 401) {
          print('EditProfilePage - Token invalide, déconnexion...');
          await _authService.logout();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _profileErrorMessage = 'Erreur: $e';
        _isProfileLoading = false;
      });
      print('EditProfilePage - Exception (updateProfile): $e');
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isPasswordLoading = true;
      _passwordErrorMessage = '';
    });

    try {
      final token = await _authService.getToken();
      print('EditProfilePage - Token (changePassword): $token');
      if (token == null) {
        throw Exception('Aucun token trouvé. Veuillez vous reconnecter.');
      }

      final updateData = {
        'oldPassword': _oldPasswordController.text.trim(),
        'newPassword': _newPasswordController.text.trim(),
      };

      final response = await http.patch(
        Uri.parse('http://10.0.2.2:6006/users/updateUser'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );

      print('EditProfilePage - PATCH /users/updateUser (password) Statut: ${response.statusCode}');
      print('EditProfilePage - PATCH /users/updateUser (password) Réponse: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _isPasswordLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe mis à jour avec succès')),
        );
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _passwordErrorMessage = errorData['message'] ?? 'Erreur lors du changement de mot de passe';
          _isPasswordLoading = false;
        });
        if (response.statusCode == 401) {
          print('EditProfilePage - Token invalide, déconnexion...');
          await _authService.logout();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _passwordErrorMessage = 'Erreur: $e';
        _isPasswordLoading = false;
      });
      print('EditProfilePage - Exception (changePassword): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: Colors.indigo[200],
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Section Profil
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations personnelles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _firstnameController,
                        decoration: InputDecoration(
                          labelText: 'Prénom',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.person, color: Colors.indigo[600]),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre prénom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastnameController,
                        decoration: InputDecoration(
                          labelText: 'Nom',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.person_outline, color: Colors.indigo[600]),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.email, color: Colors.indigo[600]),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Veuillez entrer un email valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_profileErrorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _profileErrorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      AnimatedButton(
                        onPressed: _isProfileLoading ? null : _updateProfile,
                        child: _isProfileLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Enregistrer le profil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Section Mot de passe
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Changer le mot de passe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _oldPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Ancien mot de passe',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.lock, color: Colors.indigo[600]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureOldPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.indigo[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureOldPassword = !_obscureOldPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureOldPassword,
                        validator: (value) {
                          if (_newPasswordController.text.isNotEmpty &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Veuillez entrer l\'ancien mot de passe';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Nouveau mot de passe',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.lock, color: Colors.indigo[600]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.indigo[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureNewPassword,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (value.trim().length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                          }
                          if (_oldPasswordController.text.isNotEmpty &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Veuillez entrer le nouveau mot de passe';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.lock, color: Colors.indigo[600]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.indigo[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (_newPasswordController.text.isNotEmpty &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Veuillez confirmer le mot de passe';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_passwordErrorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _passwordErrorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      AnimatedButton(
                        onPressed: _isPasswordLoading ? null : _changePassword,
                        child: _isPasswordLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Changer le mot de passe',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const AnimatedButton({super.key, required this.onPressed, required this.child});

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed!();
            }
          : null,
      onTapCancel: widget.onPressed != null ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.onPressed != null ? Colors.indigo[600] : Colors.grey,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}