import 'package:corp_syncmdm/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:corp_syncmdm/modules/user/user_provider.dart';

Future<void> logoutUser(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');

  Provider.of<UserProvider>(context, listen: false).clearUser();
  AnalyticsService.clearUser();
  Navigator.of(context).pushReplacementNamed('/login');
}
