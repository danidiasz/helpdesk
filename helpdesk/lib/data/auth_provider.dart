import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'models.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool get isAuthenticated => _currentUser != null;
  User? get user => _currentUser;
  bool get isAdmin => _currentUser?.roleName == 'admin';

  final List<User> _mockUsers = [
    User(
      id: '1',
      name: 'Admin User',
      email: 'testeadmin@teste.com',
      password: '5629362',
      role: UserRole.admin,
      roleName: 'admin',
    ),
    User(
      id: '2',
      name: 'User Test',
      email: 'testeusuario@teste.com',
      password: '5629362',
      role: UserRole.user,
      roleName: 'teste',
    ),
  ];

  Future<bool> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      final user = _mockUsers.firstWhere(
        (u) => u.email == email && u.password == password,
      );
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void updateProfile(String name) {
    if (_currentUser != null) {
      // In a real app, this would be a copyWith or mutable update
      // Since it's a mock, we'll just create a new object replacing the old one in the list
      // But for simplicity, let's just assume we can update it locally
      // Dart objects are references, but User fields are final.
      // So let's re-assign _currentUser
      _currentUser = User(
        id: _currentUser!.id,
        name: name,
        email: _currentUser!.email,
        password: _currentUser!.password,
        role: _currentUser!.role,
        roleName: _currentUser!.roleName,
      );
      notifyListeners();
    }
  }
}
