import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/screens/notes_screen.dart';

import '../providers/auth.dart';

enum AuthMode { signup, login }

const imageUrl =
    'https://img.freepik.com/free-photo/computer-security-with-login-password-padlock_107791-16191.jpg?w=1380&t=st=1691925159~exp=1691925759~hmac=abb843cdec5999a29081ca768427245cef0bd1102590f6f4dff486bbf871351f';

class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text('Notes App'),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.network(
                imageUrl,
                height: 200,
                fit: BoxFit.cover,
              ),
              AuthCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthCard extends StatefulWidget {
  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  AuthMode _authMode = AuthMode.login;
  final GlobalKey<FormState> _formKey = GlobalKey();
  final _passwordController = TextEditingController();

  final Map<String, String> _authData = {
    'email': '',
    'password': '',
  };

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('An error occured!'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Okay!'),
            ),
          ],
        );
      },
    );
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.login) {
      setState(() {
        _authMode = AuthMode.signup;
      });
    } else {
      setState(() {
        _authMode = AuthMode.login;
      });
    }
  }

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    try {
      if (_authMode == AuthMode.login) {
        // Log user in
        await Provider.of<Auth>(context, listen: false).logIn(
          email: _authData['email']!,
          password: _authData['password']!,
        );
      } else {
        // SignUp user
        await Provider.of<Auth>(context, listen: false).signUp(
          email: _authData['email']!,
          password: _authData['password']!,
        );
      }
    } on HttpException catch (error) {
      var errorMsg = 'Authentication failed!';
      if (error.message.contains('EMAIL_EXISTS')) {
        errorMsg = 'Email already in use.';
      } else if (error.message.contains('INVALID_EMAIL')) {
        errorMsg = 'Entered email address is not valid!';
      } else if (error.message.contains('WEAK_PASSWORD')) {
        errorMsg = 'Password is too weak!';
      } else if (error.message.contains('EMAIL_NOT_FOUND')) {
        errorMsg = 'Unable to find user with this email.';
      } else if (error.message.contains('INVALID_PASSWORD')) {
        errorMsg = 'Invalid password!';
      }
      _showErrorDialog(errorMsg);
    } catch (error) {
      const errorMsg = 'Authentication failed, please try again!';
      _showErrorDialog(errorMsg);
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Card(
      elevation: 50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Container(
        height: _authMode == AuthMode.signup ? 380 : 300,
        width: deviceSize.width * 0.9,
        constraints: BoxConstraints(
          minHeight: _authMode == AuthMode.signup ? 380 : 300,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty || !value.contains('@')) {
                    return 'Invalid email!';
                  }
                  return null;
                },
                onSaved: (email) {
                  _authData['email'] = email!;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
                obscureText: true,
                controller: _passwordController,
                validator: (pass) {
                  if (pass!.isEmpty || pass.length < 5) {
                    return 'Password is too short!';
                  }
                  return null;
                },
                onSaved: (pass) {
                  _authData['password'] = pass!;
                },
              ),
              if (_authMode == AuthMode.signup)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  onTapOutside: (event) => FocusScope.of(context).unfocus(),
                  obscureText: true,
                  validator: _authMode == AuthMode.signup
                      ? (pass) {
                          if (pass != _passwordController.text) {
                            return 'Password do not match';
                          }
                          return null;
                        }
                      : null,
                ),
              const SizedBox(height: 10),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30.0,
                      vertical: 8.0,
                    ),
                  ),
                  onPressed: _submit,
                  child: Text(
                    _authMode == AuthMode.login ? 'LOGIN' : 'SIGNUP',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              TextButton(
                onPressed: _switchAuthMode,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30.0,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '${_authMode == AuthMode.login ? 'SIGN UP' : 'LOGIN'} INSTEAD',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}