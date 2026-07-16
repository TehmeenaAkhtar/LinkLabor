# 🔗 LinkLabour — Skilled Worker Hiring App

A Flutter mobile application connecting skilled workers with customers in Pakistan.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat&logo=flutter)
![Node.js](https://img.shields.io/badge/Node.js-Express-339933?style=flat&logo=node.js)
![MySQL](https://img.shields.io/badge/MySQL-XAMPP-4479A1?style=flat&logo=mysql)
![AI](https://img.shields.io/badge/AI-Gemini%202.5%20Flash-4285F4?style=flat&logo=google)

---

## 📱 About the App

**LinkLabour** is a full-stack mobile application developed as a Final Year Project. It bridges the gap between customers who need skilled workers and workers who are looking for job opportunities in Pakistan.

Just like **Careem** connects riders with drivers, **LinkLabour** connects customers with verified skilled workers such as electricians, plumbers, carpenters, painters, and AC technicians.

---

## ✨ Features

### 👷 For Workers
- Register with CNIC verification and document upload
- Browse and filter open jobs by skill and location
- GPS-based nearby job search
- Apply for jobs and chat directly with customers
- Track earnings and job history
- Rate customers after job completion
- AI chatbot for job guidance

### 🙋 For Customers
- Register and post job requests
- Find verified workers by skill
- Accept or reject worker applications
- Real-time messaging with workers
- Rate workers after job completion
- AI chatbot for finding workers

### 🔐 For Admin
- Web-based admin dashboard
- Verify or unverify workers
- View worker documents (CNIC, license, certificates)
- Delete workers, customers, or jobs
- Monitor platform earnings and transactions
- Search and filter all records

### 🤖 AI Chatbot
- Powered by **Google Gemini 2.5 Flash**
- Role-aware (different behavior for worker/customer/guest)
- Fetches **real-time data** from database
- Supports both **Urdu and English**

### 🌍 Accessibility
- Full **Urdu language support**
- **Text-to-speech** on registration forms (reads labels in Urdu)
- Simple, clean UI designed for all literacy levels

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| Backend | Node.js + Express |
| Database | MySQL (XAMPP) |
| AI | Google Gemini 2.5 Flash API |
| Admin Panel | HTML + CSS + JavaScript |
| IDE | Android Studio |

---

## 📦 Flutter Packages Used

| Package | Purpose |
|---|---|
| `http` | REST API calls |
| `image_picker` | Camera and gallery image selection |
| `flutter_markdown` | Chatbot response formatting |
| `flutter_tts` | Urdu text-to-speech |
| `geolocator` | GPS location detection |
| `shared_preferences` | Local language preference storage |

---

## 🗄️ Database Tables

| Table | Description |
|---|---|
| `workers` | Worker profiles, skills, documents, location |
| `customers` | Customer profiles and documents |
| `jobs` | Job postings with budget and location |
| `job_applications` | Worker applications for jobs |
| `messages` | Real-time chat messages |
| `ratings` | Star ratings and feedback |

---

## 🚀 Getting Started

### Prerequisites

Make sure you have these installed:
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Node.js](https://nodejs.org)
- [XAMPP](https://www.apachefriends.org) (for MySQL)
- [Android Studio](https://developer.android.com/studio)

---

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/linklabour.git
cd linklabour
```

---

### 2️⃣ Database Setup

1. Open **XAMPP** → Start **Apache** and **MySQL**
2. Open **phpMyAdmin** → `http://localhost/phpmyadmin`
3. Create a new database called `users_data`
4. Run this SQL to create all tables:

```sql
CREATE TABLE workers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  fullName VARCHAR(255) NOT NULL,
  cnic VARCHAR(20) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  city VARCHAR(100),
  skill VARCHAR(100),
  availableHours VARCHAR(100),
  about TEXT,
  password VARCHAR(255),
  cnicFront LONGBLOB,
  cnicBack LONGBLOB,
  profilePic LONGBLOB,
  workCert LONGBLOB,
  license LONGBLOB,
  licenseBack LONGBLOB,
  worker_form_completed TINYINT(1) DEFAULT 0,
  avg_rating DECIMAL(3,2) DEFAULT 0,
  total_ratings INT DEFAULT 0,
  latitude DECIMAL(10,8) NULL,
  longitude DECIMAL(11,8) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  fullName VARCHAR(255) NOT NULL,
  cnic VARCHAR(20) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  city VARCHAR(100),
  cnicFront LONGBLOB,
  cnicBack LONGBLOB,
  profilePic LONGBLOB,
  avg_rating DECIMAL(3,2) DEFAULT 0,
  total_ratings INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE jobs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  worker_id INT,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  budget DECIMAL(10,2) NOT NULL,
  location VARCHAR(255),
  status ENUM('open','assigned','completed') DEFAULT 'open',
  latitude DECIMAL(10,8) NULL,
  longitude DECIMAL(11,8) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE job_applications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  job_id INT NOT NULL,
  worker_id INT NOT NULL,
  status ENUM('pending','accepted','rejected') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
  FOREIGN KEY (worker_id) REFERENCES workers(id) ON DELETE CASCADE
);

CREATE TABLE messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  job_id INT NOT NULL,
  sender_type ENUM('worker','customer') NOT NULL,
  sender_id INT NOT NULL,
  receiver_id INT NOT NULL,
  message TEXT NOT NULL,
  is_read TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
);

CREATE TABLE ratings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  job_id INT NOT NULL,
  rated_by ENUM('worker','customer') NOT NULL,
  rater_id INT NOT NULL,
  rated_id INT NOT NULL,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  feedback TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
);
```

---

### 3️⃣ Backend Setup

```bash
cd backend
npm install
node server.js
```

You should see:
```
✅ Server running on port 5000
✅ Connected to MySQL
```


### 4️⃣ Flutter App Setup

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run --release
```

---

### 5️⃣ Configure IP Address

Find your PC's IP address:
```bash
ipconfig    # Windows
ifconfig    # Mac/Linux
```

Update the base URL in all Flutter files from:
```dart
static const String _baseUrl = "http://10.0.2.2:5000";
```
To:
```dart
static const String _baseUrl = "http://YOUR_PC_IP:5000";
```

Files to update:
- `lib/gemini_service.dart`
- `lib/login_screen.dart`
- `lib/verification_screen.dart`
- `lib/screens/worker/jobs/jobs_screen.dart`
- `lib/screens/worker/profile/profile_screen.dart`
- `lib/screens/worker/wages/wages_screen.dart`
- `lib/screens/worker/chats/chats_screen.dart`
- `lib/screens/customer/jobs/my_jobs_screen.dart`
- `lib/screens/customer/profile/profile_screen.dart`
- `lib/screens/customer/chats/chats_screen.dart`
- `lib/screens/chat_screen.dart`

---

### 6️⃣ Admin Panel

Open browser and go to:
```
http://localhost:5000/admin.html
```

---

### 7️⃣ Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Create a new API key
3. Add it in `lib/gemini_service.dart`:

```dart
static const _apiKey = "YOUR_GEMINI_API_KEY";
```

---

## 📁 Project Structure

```
linklabour/
├── lib/
│   ├── screens/
│   │   ├── customer/
│   │   │   ├── chats/
│   │   │   │   └── chats_screen.dart
│   │   │   ├── jobs/
│   │   │   │   ├── my_jobs_screen.dart
│   │   │   │   └── post_job_screen.dart
│   │   │   └── profile/
│   │   │       └── profile_screen.dart
│   │   ├── worker/
│   │   │   ├── chats/
│   │   │   │   └── chats_screen.dart
│   │   │   ├── jobs/
│   │   │   │   └── jobs_screen.dart
│   │   │   ├── profile/
│   │   │   │   └── profile_screen.dart
│   │   │   └── wages/
│   │   │       └── wages_screen.dart
│   │   └── widgets/
│   │       └── bottom_nav_bar.dart
│   ├── chat_bubble.dart
│   ├── chat_screen.dart
│   ├── gemini_service.dart
│   ├── language_state.dart
│   ├── login_screen.dart
│   ├── main.dart
│   ├── rating_screen.dart
│   ├── role_selection_screen.dart
│   ├── speaker_button.dart
│   ├── tts_service.dart
│   ├── verification_screen.dart
│   ├── welcome_screen.dart
│   └── worker_registration_screen.dart
├── backend/
│   ├── server.js
│   ├── admin.html
│   └── package.json
├── assets/
│   └── images/
├── pubspec.yaml
└── README.md
```

---

## 🔄 App Flow

```
Welcome Screen
    ↓
Login Screen (phone number)
    ↓
Role Detection (worker or customer)
    ↓
Worker Dashboard          Customer Dashboard
├── Profile               ├── Profile
├── Jobs (GPS filter)     ├── My Jobs / Post Job
├── Wages / Earnings      └── Chats
└── Chats
         ↓
    Real-time Messaging
         ↓
    Job Completion
         ↓
    Rating & Feedback
```

---

## 👤 User Roles

| Role | Access |
|---|---|
| Worker | Jobs, Applications, Chat, Earnings, Profile |
| Customer | Post Jobs, Applicants, Chat, Profile |
| Admin | All data, Verify workers, Delete records, Earnings |

---

## 🔑 Key Technical Highlights

- **Phone-only login** — no password required, auto-detects worker or customer
- **CNIC verification** — admin manually verifies each worker's identity documents
- **Real-time chat** — polling every 3 seconds for new messages
- **GPS matching** — Haversine formula calculates distance between worker and job
- **AI with live data** — Gemini receives real database records to give accurate answers
- **Bytes-based upload** — images stored as bytes to avoid Android file path errors
- **Bilingual** — full Urdu and English support throughout the app


## 👥 Developer

**Tehmeena Akhtar**
**Faiza Fatima**


## 🙏 Acknowledgements

- [Flutter](https://flutter.dev) — Mobile framework
- [Google Gemini AI](https://aistudio.google.com) — AI chatbot
- [Node.js](https://nodejs.org) — Backend server
- [XAMPP](https://www.apachefriends.org) — Local database
- [Geolocator](https://pub.dev/packages/geolocator) — GPS package
