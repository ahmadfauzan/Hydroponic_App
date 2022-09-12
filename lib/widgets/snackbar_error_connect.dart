import 'package:flutter/material.dart';

class SnackbarErrorConnect extends StatelessWidget {
  const SnackbarErrorConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          var snackBar = SnackBar(content: Text('Hello World'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        },
        child: Text('Show SnackBar'),
      ),
    );
  }
}
