import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:corp_syncmdm/services/auth_service.dart';

class CustomDrawer extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  CustomDrawer({required this.isDarkMode, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text('Nome do Usuário'),
            accountEmail: Text('email@exemplo.com'),
            currentAccountPicture: CircleAvatar(
              backgroundImage:
                  AssetImage('assets/images/Logo.png') as ImageProvider,
            ),
            decoration: BoxDecoration(color: Color(0xFF259073)),
            otherAccountsPictures: <Widget>[
              IconButton(
                icon: Icon(
                  isDarkMode ? Icons.nights_stay : Icons.wb_sunny,
                  color: Colors.white,
                ),
                onPressed: () {
                  onThemeChanged(!isDarkMode);
                },
              ),
            ],
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            },
          ),
          ExpansionTile(
            leading: Icon(Icons.smartphone),
            title: Text('Dispositivos'),
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.list),
                title: Text('Lista de Dispositivos'),
                onTap: () {
                  Navigator.of(context).pushReplacementNamed('/dispositivos');
                },
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Adicionar Dispositivo'),
                onTap: () {
                  Navigator.of(context).pushReplacementNamed('/dispositivos/add');
                },
              ),
            ],
          ),
          ExpansionTile(
            leading: Icon(Icons.supervised_user_circle),
            title: Text('Usuarios'),
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.list),
                title: Text('Usuarios'),
                onTap: () {
                  Navigator.of(context).pushReplacementNamed('/usuario');
                },
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Cadastrar Usuarios'),
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed('/usuario/cadastro');
                },
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () => logoutUser(context),
          ),
        ],
      ),
    );
  }
}
