import 'package:anon_chat/providers/theme_provider.dart';
import 'package:anon_chat/providers/user_provider.dart';
import 'package:anon_chat/screens/find_user_page.dart';
import 'package:anon_chat/screens/group_page.dart';
import 'package:anon_chat/screens/home_page.dart';
import 'package:anon_chat/screens/profile_change.dart';
import 'package:anon_chat/screens/sign_up_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomDrawer {
  BuildContext context;
  CustomDrawer({required this.context});

  Widget drawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
            color: Provider.of<ThemeProvider>(context).secondaryBg),
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: (Provider.of<UserProvider>(context).profile != "")
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                            Provider.of<UserProvider>(context).profile),
                        fit: BoxFit.cover, // Adjust fit as needed
                      ),
                    )
                  : BoxDecoration(
                      color: Provider.of<ThemeProvider>(context).thirdBg),
              child: (Provider.of<UserProvider>(context).profile != "")
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            Provider.of<UserProvider>(context)
                                .username
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w700),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileChange()));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Provider.of<ThemeProvider>(context)
                                  .primaryText,
                            ),
                          ),
                        )
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              Provider.of<UserProvider>(context)
                                  .username
                                  .toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileChange()));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Provider.of<ThemeProvider>(context)
                                  .primaryText,
                            ),
                          ),
                        )
                      ],
                    ),
            ),

            // friends
            Expanded(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.search_rounded,
                      color: Provider.of<ThemeProvider>(context).primaryText,
                    ),
                    title: Text(
                      "Search",
                      style: TextStyle(
                        color: Provider.of<ThemeProvider>(context).primaryText,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FindUserPage()));
                    },
                  ),

                  // chats
                  ListTile(
                    leading: Icon(
                      Icons.chat_rounded,
                      color: Provider.of<ThemeProvider>(context).primaryText,
                    ),
                    title: Text(
                      "Inbox",
                      style: TextStyle(
                        color: Provider.of<ThemeProvider>(context).primaryText,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ));
                    },
                  ),

                  // groups
                  ListTile(
                    leading: Icon(
                      Icons.groups_rounded,
                      color: Provider.of<ThemeProvider>(context).primaryText,
                    ),
                    title: Text(
                      "Groups",
                      style: TextStyle(
                        color: Provider.of<ThemeProvider>(context).primaryText,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GroupPage(),
                          ));
                    },
                  ),

                  // logout
                  ListTile(
                    leading: Icon(
                      Icons.logout_rounded,
                      color: Provider.of<ThemeProvider>(context).primaryText,
                    ),
                    title: Text(
                      "Log Out",
                      style: TextStyle(
                        color: Provider.of<ThemeProvider>(context).primaryText,
                      ),
                    ),
                    onTap: () {
                      Provider.of<UserProvider>(context, listen: false)
                          .updateUserCredentials(name: "", profileUrl: "");
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()));
                    },
                  ),
                ],
              ),
            ),

            Text(
              "powered by The Nayem Codex",
              style: TextStyle(
                color: Provider.of<ThemeProvider>(context).thirdText,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
            const SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }
}
