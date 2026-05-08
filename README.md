# 🍽️ KhajaKham - Online Food Ordering App

KhajaKham is a modern **online food ordering mobile application** built using **Flutter** and **Firebase**. It allows users to browse food items, add them to cart, place orders, and track order status in real time with a smooth and responsive UI.

---

## 📱 Features

- 🍔 **Browse Categories:** Explore various food categories and items.
- 🛒 **Cart Management:** Add, remove, and manage items easily.
- 📦 **Order Tracking:** Place orders and track status in real-time.
- 🔐 **Authentication:** Secure login/signup via Firebase Auth (Email & Password).
- ❤️ **Favorites:** Save your favorite food items for quick access.
- 🔔 **Notifications:** Stay updated with order status alerts.
- 👤 **Profile Management:** Manage user details and order history.
- ⚡ **Responsive UI:** Fast and fluid performance across devices.

---

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase
- **Authentication:** Firebase Auth
- **Database:** Cloud Firestore
- **Storage:** Firebase Storage
- **Notifications:** Firebase Cloud Messaging (FCM), Fluter local notification.

---

## 📂 Project Structure

```text
lib/
│
├── models/          # Data models (User, Food, Order, etc.)
├── screens/         # App screens (Home, Cart, Profile, etc.)
├── widgets/         # Reusable UI components
├── services/        # Firebase & API services
├── providers/       # State management (Provider/Riverpod)
├── utils/           # Helpers, constants, and theme data
└── main.dart        # Entry point of the application
```

## 🚀 Getting Started
1. Clone the repository bash ``` git clone [https://github.com/your-username/khajakham.git](https://github.com/sanjit404/khajakham.git) ```
- bash ``` cd khajakham ```
2. Install dependencies bash ``` flutter pub get```
3. Setup FirebaseCreate a project on the Firebase Console.Enable Authentication, Firestore, and Storage.
Download the configuration files:google-services.json → Place in android/app/GoogleService-Info.
4. Run the app bash``` flutter run```
