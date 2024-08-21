import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:convert';

void main() {
  runApp(ContactFormApp());
}

class ContactFormApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ContactFormScreen(),
    );
  }
}

class ContactFormScreen extends StatefulWidget {
  @override
  _ContactFormScreenState createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  String _selectedGender = 'Male';
  final _ageController = TextEditingController();
  XFile? _selfieImage;
  final ImagePicker _picker = ImagePicker();
  Position? _currentPosition;
  String? _audioFilePath;
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _submissionTime;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _recorder!.closeRecorder();
    super.dispose();
  }

  Future<void> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    _currentPosition = await Geolocator.getCurrentPosition();
  }

  Future<void> _startRecording() async {
    Directory tempDir = await getTemporaryDirectory();
    String path = '${tempDir.path}/audio_recording.wav';
    await _recorder!.startRecorder(toFile: path);
    setState(() {
      _audioFilePath = path;
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _submitForm() async {
    String age = _ageController.text;
    if (age.isEmpty || _selfieImage == null || _audioFilePath == null) {
      _showDialog('Please fill all the fields, upload a selfie, and record audio.');
      return;
    }

    await _getCurrentPosition();

    _submissionTime = DateTime.now().toIso8601String();

    Map<String, dynamic> formData = {
      'gender': _selectedGender,
      'age': age,
      'selfie': _selfieImage!.path,
      'audio': _audioFilePath,
      'gps': '${_currentPosition!.latitude},${_currentPosition!.longitude}',
      'submission_time': _submissionTime,
    };

    Directory appDocDir = await getApplicationDocumentsDirectory();
    File jsonFile = File('${appDocDir.path}/submission_data.json');
    await jsonFile.writeAsString(json.encode(formData));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(formData: formData),
      ),
    );
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selfieImage = pickedFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Form'),
      ),
      body: Container(
        color: Color.fromARGB(245, 164, 134, 23), // Set background color here
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select your gender:'),
            DropdownButton<String>(
              value: _selectedGender,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue!;
                });
              },
              items: <String>['Male', 'Female', 'Other']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            Text('Enter your age:'),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Age',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Upload Selfie'),
            ),
            if (_selfieImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Image.file(
                  File(_selfieImage!.path),
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 16.0),
            _isRecording
                ? ElevatedButton(
                    onPressed: _stopRecording,
                    child: Text('Stop Recording'),
                  )
                : ElevatedButton(
                    onPressed: _startRecording,
                    child: Text('Start Recording'),
                  ),
            SizedBox(height: 24.0),
            Center(
              child: ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final Map<String, dynamic> formData;

  ResultPage({required this.formData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result'),
      ),
      body: Container(
        color: Colors.lightGreen[50], // Set background color here
        padding: const EdgeInsets.all(16.0),
        child: Table(
          border: TableBorder.all(),
          children: [
            TableRow(
              children: [
                Text('Q1', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Q2', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Q3', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('RecordedAudio', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('GPS', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('SubmissionTime', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            TableRow(
              children: [
                Text(formData['gender']),
                Text(formData['age']),
                Image.file(
                  File(formData['selfie']),
                  width: 100,
                  height: 100,
                ),
                TextButton(
                  onPressed: () {
                    _playAudio(formData['audio']);
                  },
                  child: Text('Play Audio'),
                ),
                Text(formData['gps']),
                Text(formData['submission_time']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _playAudio(String path) {
    FlutterSoundPlayer player = FlutterSoundPlayer();
    player.openPlayer();
    player.startPlayer(fromURI: path);
  }
}
