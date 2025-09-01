import 'package:flutter/material.dart';
import 'package:ra_tooltip/tooltip/tooltip.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExampleTooltip(),
    );
  }
}

class ExampleTooltip extends StatefulWidget {
  const ExampleTooltip({super.key});

  @override
  State<ExampleTooltip> createState() => _ExampleTooltipState();
}

class _ExampleTooltipState extends State<ExampleTooltip> {
  // List of colors for each tooltip
  List<Color> _tooltipColors = [
    const Color(0xFF333F47),
    const Color(0xFF333F47),
    const Color(0xFF333F47),
    const Color(0xFF333F47),
  ];

  final List<Color> _colorChoices = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.pink,
    Colors.brown,
    Colors.indigo,
    const Color(0xFF333F47),
  ];

  void _randomizeColors() {
    final random = Random();
    setState(() {
      _tooltipColors = List.generate(
        4,
        (_) => _colorChoices[random.nextInt(_colorChoices.length)],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: _tooltipColors[0],
        onPressed: _randomizeColors,
        child: const Icon(Icons.color_lens, color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RATooltip(
              message: 'Example Message',
              color: _tooltipColors[0],
              trigger: RATooltipTrigger.tap,
              child: Text(
                'Label',
                style: GoogleFonts.aBeeZee(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RATooltip(
                  position: RATooltipPosition.left,
                  message: 'Example\nMessage',
                  color: _tooltipColors[1],
                  child: Text(
                    'Label',
                    style: GoogleFonts.aBeeZee(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                RATooltip(
                  position: RATooltipPosition.right,
                  message: 'Example\nMessage',
                  color: _tooltipColors[2],
                  child: Text(
                    'Label',
                    style: GoogleFonts.aBeeZee(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 24,
            ),
            RATooltip(
              position: RATooltipPosition.bottom,
              message: 'Example Message',
              color: _tooltipColors[3],
              child: Text(
                'Label',
                style: GoogleFonts.aBeeZee(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            RATooltip(
              trigger: RATooltipTrigger.hold,
              message: 'Hold me for 800ms!',
              position: RATooltipPosition.bottom,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple),
                ),
                child: Text(
                  'Hold this button',
                  style: GoogleFonts.aBeeZee(
                      color: Colors.deepPurple,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
