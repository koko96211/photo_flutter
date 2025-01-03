import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_sharing_app/bloc/theme_bloc.dart';
import 'package:photo_sharing_app/bloc/theme_event.dart';
import 'package:photo_sharing_app/theme/theme_manager.dart';
import 'package:provider/provider.dart';
import 'package:photo_sharing_app/widgets/othertile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

FirebaseAuth _auth = FirebaseAuth.instance;
final User? user = _auth.currentUser;

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    getCurrentUserUID();
    super.initState();
  }

  void getCurrentUserUID() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        uid = user.uid;
        email = user.email!;
      });
    }
  }

  String email = 'default@gmail.com',
      name = 'ローディング...',
      username = 'ローディング...',
      uid = 'default';
  bool switchResult = ThemeManager.readTheme();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("公開設定"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey,
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            switchResult = !switchResult;
          });
          if (switchResult) {
            ThemeManager.saveTheme(true);
            profileServices.publicAccount(uid, true);
          } else {
            ThemeManager.saveTheme(false);
            profileServices.publicAccount(uid, false);
          }
          context.read<ThemeBloc>().add(ThemeDarkedMode());
        },
        child: Container(
          margin: const EdgeInsets.all(25.0),
          padding: const EdgeInsets.all(15.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: const BorderRadius.all(
              Radius.circular(15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("公開"),
              CupertinoSwitch(
                value: switchResult,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
