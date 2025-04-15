# CivicSense - Community Engagement Platform

## Team

Team KnightCoders

## Project Overview

CivicSense is a comprehensive civic engagement platform designed to bridge the gap between citizens and local authorities. The platform enables citizens to report civic issues, access health resources, engage with community posts, and interact through an intelligent chatbot assistant.

### Key Features

- **Complaint Management**: Citizens can report civic issues with location details, images, and descriptions, while officials can track and manage these complaints.
- **Community Messaging**: A social platform for community announcements and discussions.
- **Health Check Tools**: 
  - Skin disease detection using ML models
  - Diabetes prediction and health assessments
- **Intelligent Chatbot**: AI-powered assistant to answer queries about civic services and health concerns.
- **User Authentication**: Different user roles (citizen/official) with tailored experiences.

## Tech Stack

### Frontend
- **Flutter**: Cross-platform UI framework for mobile applications
- **Dart**: Programming language for Flutter development
- **Packages**:
  - `dialog_flowtter`: For chatbot integration
  - `flutter_dotenv`: Environment variable management
  - `hive_flutter`: Local data storage
  - `image_picker`: For camera and gallery access
  - `http`: API communication

### Backend
- **Strapi**: Headless CMS for API development
- **Node.js**: Runtime environment
- **SQLite**: Database (via better-sqlite3)

### Machine Learning
- **Python**: Primary language for ML components
- **PyTorch**: For deep learning models
  - Skin disease classification
  - Diabetes prediction
  - Deepfake detection
- **Flask**: API endpoints for ML model inference

## Setup and Installation

### Prerequisites
- Flutter SDK (latest stable version)
- Node.js (>=18.0.0 <=22.x.x)
- Python 3.x with pip
- Git

### Frontend Setup

1. Clone the repository
   ```bash
   git clone https://github.com/jaivardhan-bhola/esochackx-KnightCoders.git
   cd esochackx-KnightCoders/frontend
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Create a `.env` file in the frontend directory with the following content:
   ```
   HOST=your_host_here
   PORT=your_port_here
   VAR_API_TOKEN=your_var_api_token
   USER_API_TOKEN=your_user_api_token
   ```

4. Run the application
   ```bash
   flutter run
   ```

### Backend Setup

1. Navigate to the backend directory
   ```bash
   cd ../backend/my-strapi-project
   ```

2. Install dependencies
   ```bash
   npm install
   ```

3. Create a `.env` file in the backend directory with the following content:
   ```
   HOST=0.0.0.0
   PORT=7123
   APP_KEYS="your_app_key_1,your_app_key_2"
   API_TOKEN_SALT=your_api_token_salt
   ADMIN_JWT_SECRET=your_admin_jwt_secret
   TRANSFER_TOKEN_SALT=your_transfer_token_salt
   JWT_SECRET=your_jwt_secret
   ```

4. Start the development server
   ```bash
   npm run develop
   ```

### ML Setup

1. Navigate to the ML directory
   ```bash
   cd ../../ml
   ```

2. Install Python dependencies
   ```bash
   pip install -r requirements.txt
   ```

3. Create a `.env` file in the ml directory with the following content:
   ```
   GROQ_API_KEY=your_groq_api_key
   SERPER_API_KEY=your_serper_api_key
   TF_ENABLE_ONEDNN_OPTS=your_tf_enable_onednn_opts
   ```

4. Run the API server
   ```bash
   python api.py
   ```

## Environment Dependencies

### Flutter/Dart
- Flutter SDK
- Android Studio / Xcode for mobile deployment
- Required packages listed in `pubspec.yaml`

### Backend
- Node.js v18+
- npm or yarn
- Strapi v5.12.4
- Database: better-sqlite3 v11.3.0

### ML Components
- Python 3.x
- PyTorch
- Flask
- Datasets:
  - Deepfake detection: [Deepfake Detection Challenge Dataset](https://www.kaggle.com/competitions/deepfake-detection-challenge/data)
  - Skin disease classification: [HAM10000](https://www.kaggle.com/datasets/kmader/skin-cancer-mnist-ham10000)
  - Diabetes predictor: [Pima Indians Diabetes Database](https://www.kaggle.com/datasets/uciml/pima-indians-diabetes-database)

## Design Materials

- UI Design: [Figma Design](https://www.figma.com/design/VvDOUjGg7R2rzXFtbhMAfI/Esoc-x-hack?node-id=0-1&p=f&t=BMe5v09Wfzs0jDHX-0)

## Project Structure

```
└── esochackx-KnightCoders/
    ├── backend/             # Strapi backend
    │   ├── my-strapi-project/
    │   └── server.js
    ├── frontend/           # Flutter application
    │   ├── assets/         # Images and resources
    │   ├── lib/            # Dart source files
    │   │   ├── services/   # API services
    │   │   └── widgets/    # Reusable UI components
    │   └── pubspec.yaml    # Flutter dependencies
    └── ml/                 # Machine learning models
        ├── health0check-feature/
        │   ├── diabetes_model.sav
        │   └── skin-disease-model2.pth
        ├── deepfake_model.pt
        └── api.py          # Flask API endpoints
```