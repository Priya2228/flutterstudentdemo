import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("Initializing Firebase...");
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyBB1NwCDfpFNzFPAHAj6vinXa_K8Thy798",
          authDomain: "studentdemo-d5391.firebaseapp.com",
          databaseURL:
              "https://naqli-5825c-default-rtdb.europe-west1.firebasedatabase.app",
          projectId: "studentdemo-d5391",
          storageBucket: "studentdemo-d5391.appspot.com",
          messagingSenderId: "948878576246",
          appId: "1:948878576246:web:04a3695f757e8c84c56d57",
          measurementId: "G-F4GKJSRZC0"));
  print("Firebase initialized successfully!");
  runApp(StudentFormApp());
}

class StudentFormApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StudentFormPage(),
    );
  }
}

class StudentFormPage extends StatefulWidget {
  @override
  _StudentFormPageState createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text;
      int age = int.tryParse(_ageController.text) ?? 0; // Handle invalid input gracefully
      String department = _departmentController.text;

      try {
        // Add or update the form data to Firestore
        if (_selectedStudent == null) {
          // Add new student
          await FirebaseFirestore.instance.collection('students').add({
            'name': name,
            'age': age,
            'department': department,
          });
        } else {
          // Update existing student
          await FirebaseFirestore.instance
              .collection('students')
              .doc(_selectedStudent!.id)
              .update({
                'name': name,
                'age': age,
                'department': department,
              });
        }

        // Clear the form fields after submission or update
        _nameController.clear();
        _ageController.clear();
        _departmentController.clear();

        // Show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_selectedStudent == null ? 'Student added successfully!' : 'Student updated successfully!')),
        );
        
        // Reset selected student after update
        _selectedStudent = null;

      } catch (e) {
        // Handle Firestore errors
        print('Error adding/updating student data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add/update student data. Please try again later.')),
        );
      }
    }
  }

  Future<void> _deleteStudent(String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('students').doc(documentId).delete();

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student deleted successfully!')),
      );

    } catch (e) {
      // Handle Firestore errors
      print('Error deleting student data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete student data. Please try again later.')),
      );
    }
  }

  QueryDocumentSnapshot? _selectedStudent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an age';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _departmentController,
                    decoration: InputDecoration(labelText: 'Department'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a department';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text('Submit'),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // Clear form fields and selection
                            _nameController.clear();
                            _ageController.clear();
                            _departmentController.clear();
                            _selectedStudent = null;
                          });
                        },
                        child: Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _buildStudentList(), // Widget to display list of students
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // If we reach here, we have data
        final students = snapshot.data!.docs;

        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            var student = students[index];
            var studentData = student.data() as Map<String, dynamic>?;

            if (studentData == null) {
              return SizedBox(); // Placeholder or loading indicator for null case
            }

            return ListTile(
              title: Text(studentData['name'] ?? 'Unknown'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Age: ${studentData['age'] ?? 'Unknown'}'),
                  Text('Department: ${studentData['department'] ?? 'Unknown'}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        // Populate form fields for update
                        _selectedStudent = student;
                        _nameController.text = studentData['name'] ?? '';
                        _ageController.text = (studentData['age'] ?? '').toString();
                        _departmentController.text = studentData['department'] ?? '';
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Confirm Delete"),
                            content: Text("Are you sure you want to delete this student?"),
                            actions: [
                              TextButton(
                                child: Text("Cancel"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text("Delete"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _deleteStudent(student.id);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _departmentController.dispose();
    super.dispose();
  }
}
