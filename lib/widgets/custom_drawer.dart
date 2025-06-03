import 'package:corp_syncmdm/modules/user/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:corp_syncmdm/services/auth_service.dart';
import 'package:corp_syncmdm/utils/base64_utils.dart';

class CustomDrawer extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  CustomDrawer({required this.isDarkMode, required this.onThemeChanged});
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    Uint8List? imageBytes;
    if (user?.profileImageBase64 != null && user!.profileImageBase64!.isNotEmpty) {
      try {
        String base64String = user.profileImageBase64!;
        
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }
        
        while (base64String.length % 4 != 0) {
          base64String += '=';
        }
        
        imageBytes = base64Decode(base64String);
      } catch (e) {
        print('Erro ao decodificar imagem Base64 no drawer: $e');
        imageBytes = null;
      }
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'Nome do Usuário'),
            accountEmail: Text(user?.email ?? 'email@exemplo.com'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: imageBytes != null
                  ? MemoryImage(imageBytes)
                  : AssetImage('assets/images/default_user_image.png')
              as ImageProvider,
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
            title: Text('Usuários'),
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.list),
                title: Text('Usuários'),
                onTap: () {
                  Navigator.of(context).pushReplacementNamed('/usuarios');
                },
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Cadastrar Usuários'),
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed('/usuarios/add');
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
