# Face Attendance App

A Flutter-based mobile application that uses deep learning for automated attendance marking through face recognition. Built as a 5th semester Machine Learning course lab mid project.

## 👥 Developers
- **Abdul Haseeb** (FA23-BCS-120)

## 📋 Overview

This mobile application leverages facial recognition technology to automate attendance marking. Students are enrolled by capturing multiple facial images, which are then processed using a FaceNet model to generate unique embeddings. During attendance, the app continuously detects and recognizes faces in real-time, automatically marking attendance when a match is found.

## ✨ Features

### Core Functionality
- **Real-time Face Detection**: Uses Google ML Kit for fast and accurate face detection
- **Face Recognition**: Employs FaceNet model (TFLite) to generate 512-dimensional face embeddings
- **Student Enrollment**: Captures 10 photos per student to create robust face encodings
- **Automated Attendance**: Marks attendance automatically when a registered face is recognized
- **Attendance Management**: View, manage, and clear attendance records
- **Visual Feedback**: Face bounding boxes with color coding (green for recognized, red for unknown)
- **Audio/Haptic Feedback**: Alerts when attendance is marked

### Technical Features
- Singleton pattern for service management
- SQLite database for persistent attendance storage
- JSON-based face encoding storage
- Cosine similarity for face matching
- Image preprocessing and normalization
- Camera lifecycle management

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                          # App entry point
├── models/
│   ├── attendance_record.dart         # Attendance data model
│   └── face_encoding.dart             # Face embedding model
├── screens/
│   ├── camera_screen.dart             # Main screen with face recognition
│   ├── add_student_screen.dart        # Student enrollment screen
│   └── attendance_list_screen.dart    # Attendance records display
├── services/
│   ├── attendance_service.dart        # Database operations
│   ├── camera_service.dart            # Camera management
│   └── face_recognition_service.dart  # ML model operations
└── utils/
    └── constants.dart                 # App constants
```

## 🔬 Machine Learning Pipeline

### Face Recognition Workflow

1. **Face Detection**: Google ML Kit detects faces in camera frames
2. **Face Cropping**: Detected face region is extracted from the image
3. **Preprocessing**: Face is resized to 160x160 and normalized (0-1 range)
4. **Embedding Generation**: FaceNet model generates 512-dimensional embedding
5. **Face Matching**: Cosine similarity computed against stored embeddings
6. **Recognition**: Match found if similarity > 0.6 threshold

### Enrollment Process

1. Capture 10 photos of student's face
2. Generate embeddings for each photo
3. Average all embeddings to create a robust representation
4. Store averaged embedding with student name

### Model Details

- **Model**: FaceNet (TensorFlow Lite)
- **Input Size**: 160x160x3 RGB image
- **Output Size**: 512-dimensional embedding vector
- **Similarity Metric**: Cosine similarity
- **Recognition Threshold**: 0.6

## 🛠️ Technologies Used

### Framework & Language
- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language

### Key Dependencies
- `tflite_flutter` (^0.11.0) - TensorFlow Lite inference
- `google_mlkit_face_detection` (^0.10.0) - Face detection
- `camera` (^0.10.5) - Camera access
- `sqflite` (^2.3.0) - Local database
- `image` (^4.0.0) - Image processing
- `path_provider` (^2.1.0) - File system access
- `audioplayers` (^5.0.0) - Audio feedback

## 📱 Screens

### 1. Camera Screen (Main)
- Real-time face detection and recognition
- Live camera preview with face overlay
- Navigation to enrollment and attendance views
- Status display for recognized faces

### 2. Add Student Screen
- Text input for student name
- Automated photo capture (10 photos)
- Progress indicator during enrollment
- Real-time feedback

### 3. Attendance List Screen
- Display today's attendance records
- Swipe-to-delete functionality
- Clear all attendance option
- Pull-to-refresh support

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK (>=3.0.0)
- Android Studio / Xcode
- Android device/emulator with camera
- FaceNet TFLite model file

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd mobile_app_face_attendance_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. **Important**: Add FaceNet model
   - Download a FaceNet TFLite model (512-dimensional output)
   - Place it at `assets/models/facenet_model.tflite`
   - Ensure the model expects 160x160x3 input

4. Run the app:
```bash
flutter run
```

## ⚙️ Configuration

### Constants (lib/utils/constants.dart)
- `faceRecognitionThreshold`: 0.6 (adjust for stricter/looser matching)
- `photoCountForEnrollment`: 10 (number of photos per student)
- `faceInputSize`: 160 (model input dimension)
- `faceEmbeddingSize`: 512 (embedding vector size)

## 📊 How It Works

### Attendance Marking Flow
1. App opens with camera screen
2. Camera continuously captures frames (1 per second)
3. Face detector processes each frame
4. If face detected → extract and preprocess face region
5. Generate embedding using FaceNet model
6. Compare with stored embeddings using cosine similarity
7. If match found (similarity > 0.6):
   - Check if already marked today
   - If not marked → mark attendance + play alert
   - Display student name with green overlay

### Enrollment Flow
1. Navigate to "Add Student"
2. Enter student name
3. Click "Capture 10 Photos"
4. App automatically captures 10 photos over ~10 seconds
5. Only frames with detected faces are saved
6. Embeddings are generated and averaged
7. Averaged embedding stored with student name

## 🔒 Data Storage

### SQLite Database (attendance.db)
- Table: `attendance`
- Columns: `id`, `name`, `date`, `time`, `status`
- Stores historical attendance records

### JSON File (encodings.json)
- Stored in app documents directory
- Contains face embeddings and associated names
- Format: `{ "encodings": [[...]], "names": [...] }`

## 🎯 Use Cases

- **Educational Institutions**: Automate classroom attendance
- **Corporate Offices**: Employee check-in systems
- **Events**: Track attendee participation
- **Training Sessions**: Monitor participant attendance

## 🐛 Known Issues & Solutions

### Model Not Loading
- **Error**: "Failed to load FaceNet model"
- **Solution**: Ensure `facenet_model.tflite` is properly placed in assets folder

### Camera Permission Denied
- **Solution**: Enable camera permissions in device settings

### Poor Recognition Accuracy
- **Solutions**: 
  - Adjust `faceRecognitionThreshold` in constants
  - Ensure good lighting during enrollment
  - Capture photos from different angles

## 🔮 Future Enhancements

- [ ] Add support for multiple face enrollment per person
- [ ] Implement face liveness detection to prevent spoofing
- [ ] Export attendance reports (CSV/PDF)
- [ ] Cloud backup for face encodings
- [ ] Multi-session attendance tracking
- [ ] Statistics and analytics dashboard
- [ ] Admin authentication
- [ ] Dark mode support

## 📄 License

This project is developed for educational purposes as part of a Machine Learning course lab assignment.

## 🤝 Contributing

This is an academic project. For any suggestions or improvements, please contact the developers.

## 📧 Contact

For queries or collaboration:
- Abdul Haseeb: abdlhaseeb17@gmail.com

---


