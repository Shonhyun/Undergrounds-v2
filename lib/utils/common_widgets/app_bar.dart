import 'package:flutter/material.dart';

PreferredSize buildAppBar(
  BuildContext context,
  String title, { // Anything inside the {} are optional parameters
  Widget? leading, // Use this to add a back button or custom widget
  bool automaticallyImplyLeading =
      false, // Some of the dart files have this as true so I made it an optional parameter
}) {
  final theme = Theme.of(context); // Retrieves the current theme

  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: ClipRRect(
      child: AppBar(
        leading:
            leading, // Defaults to null when automaticallyImplyLeading: false is activated
        title: Text(
          title,
          style:
              theme
                  .appBarTheme
                  .titleTextStyle, // Use the theme's titleTextStyle
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
    ),
  );
}
