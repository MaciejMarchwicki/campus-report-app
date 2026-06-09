import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              "Project Creators",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 20),

            Text("Hanna Petrova - 258601@edu.p.lodz.pl"),
            Text("Maciej Marchwicki - 250366@edu.p.lodz.pl"),
            Text("Artur Jura - 257298@edu.p.lodz.pl"),
            Text("Aleksandra Wrótniak - 257784@edu.p.lodz.pl"),
          ],
        ),
      ),
    );
  }
}