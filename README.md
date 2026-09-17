## Firebase Configuration

This application uses Firebase for authentication and database operations.

### Prerequisites

Before running the application, make sure you have:

- Flutter SDK installed
- A Firebase project
- Firebase CLI installed
- FlutterFire CLI installed

### Firebase Setup

1. Create a project in the Firebase Console.

2. Enable the required Firebase services:
   - Firebase Authentication
   - Cloud Firestore

3. Enable the authentication method used by the application, such as:
   - Email/Password

4. Install FlutterFire CLI if it is not already installed:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure

   


