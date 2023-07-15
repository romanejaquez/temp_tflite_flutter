import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

void main() {
  runApp(
    const ProviderScope(
      child: TempApp()
    )
  );
}

class TempApp extends StatelessWidget {
  const TempApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme()
      ),
      home: const TempAppMain(),
    );
  }
}

class TempAppMain extends ConsumerStatefulWidget {
  const TempAppMain({super.key});

  @override
  ConsumerState<TempAppMain> createState() => _TempAppMainState();
}

class _TempAppMainState extends ConsumerState<TempAppMain> {

  double yPosition = 0;
  double initialValue = 0;
  bool initialValueSet = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    if (!initialValueSet) {
      initialValue = MediaQuery.sizeOf(context).height - 200;
      yPosition = initialValue;
      initialValueSet = true;
    }

    return Scaffold(
      body: Stack(
        children: [
          TempSlider(initialYPosition: yPosition),
          
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TempInfoDisplay(),
                TempMLDisplay()
              ],
            ),
          ),
          
          TempSlideDetector(initialYPosition: yPosition)
        ],
      )
    );
  }
}

class TempSlider extends ConsumerWidget {

  final double initialYPosition;
  const TempSlider({
    required this.initialYPosition,
    super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    var tempValue = ref.watch(tempValueProvider);
    var verticalPosition = ref.watch(sliderValueProvider);
    var yPosition = verticalPosition > 0 ? verticalPosition : initialYPosition;

    var calculatedOpacity = (1 - (tempValue * 0.025));
    calculatedOpacity = calculatedOpacity < 0 ? 0 : calculatedOpacity;

    return Stack(
        children: [

          // background container
          Container(
            color: Color.fromRGBO((tempValue.toInt() + 75), 0, 255 - (tempValue.toInt() + 75), 1)
          ),

          // background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.8)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter
              )
            )
          ),

          // slider container
          Positioned.fill(
            top: yPosition,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO((tempValue.toInt() + 75), 0, 255 - (tempValue.toInt() + 75), 1),
                    Color.fromRGBO((tempValue.toInt() + 75), 0, 255 - (tempValue.toInt() + 75), 0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50))
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Opacity(
                  opacity:  calculatedOpacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swipe_vertical, size: 40, color: Colors.white)
                      .animate(
                        onComplete: (controller) {
                          controller.repeat();
                        },
                      ).slideY(
                        begin: 0.5, end: 0,
                        duration: 1.seconds,
                        curve: Curves.easeInOut
                      ).fadeIn(),
                      const SizedBox(height: 30),
                      const Text(
                        'Drag up and down the screen\nto change temperature', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ]
    );
  }
}

// widget to detect sliding up and down the screen
class TempSlideDetector extends ConsumerStatefulWidget {

  final double initialYPosition;
  const TempSlideDetector({
    required this.initialYPosition,
    super.key
  });
  
  @override
  TempSlideDetectorState createState() => TempSlideDetectorState();
}

class TempSlideDetectorState extends ConsumerState<TempSlideDetector> {

  double yPosition = 0;
  double offset = 5;
  double tempValue = 0;
  double tempIncrement = 1;

  @override
  void initState() {
    super.initState();

    yPosition = widget.initialYPosition;
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onVerticalDragUpdate: (details) {

        if (details.delta.dy > 0) { // dragging dowwards
          if (tempValue > 0) {
            yPosition += offset;
            tempValue -= tempIncrement;
          }
        }
        else { // dragging upwards
          if (tempValue < 100) {
            yPosition -= offset;
            tempValue += tempIncrement;
          }
        }

        ref.read(sliderValueProvider.notifier).state = yPosition;
        ref.read(tempValueProvider.notifier).state = tempValue;
      },
      child: Container(
        color: Colors.transparent,
      ),
    );
  }
}

// widget to display the value from the slider (from 0 to 100)
class TempInfoDisplay extends ConsumerWidget {
  const TempInfoDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    IconData iconWidget = Icons.ac_unit;
    final tempValue = ref.watch(tempValueProvider);

    // set the appropriate icon widget
    if (tempValue >= 30) {
      iconWidget = Icons.local_fire_department;
    }
    else if (tempValue >= 15 && tempValue < 30) {
      iconWidget = Icons.waves;
    }

    return Column(
      children: [
        Icon(iconWidget, size: 100, color: Colors.white), 
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.thermostat, size: 60, color: Colors.white),
            Text('${tempValue.toInt()}°c', 
              style: const TextStyle(fontSize: 90, color: Colors.white)
            ),
          ],
        ),
      ],
    );
  }
}

// widget to display the temperature value generated by the ML model
class TempMLDisplay extends ConsumerWidget {

  const TempMLDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tempValue = ref.watch(tempValueProvider);
    final processedTempValue = ref.watch(tfLiteProvider(tempValue));

    return processedTempValue.when(
      data:(data) {
        return Text('${data.round()}°f', style: const TextStyle(color: Colors.white, fontSize: 30));
      }, 
      error:(error, stackTrace) => Text(error.toString()), 
      loading:() => const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white),),
    );
  }
}

// tracks the current value being generated by the slider
final sliderValueProvider = StateProvider<double>((ref) => 0.0);

// tracks the temperature value generated by the slider
final tempValueProvider = StateProvider<double>((ref) => 0);

// provides the value generated by the trained ML model given the proper input
final tfLiteProvider = FutureProvider.family<double, double>((ref, arg) async {

  final interpreter = await tfl.Interpreter.fromAsset('assets/models/modelc2f.tflite');
  final output = List<double>.filled(1, 0).reshape([1,1]);
  final input = [[arg]];

  interpreter.run(input, output);
  return output[0][0] as double;
});
