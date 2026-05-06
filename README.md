# Phở Cẩm Phả - OnSeat Order System 🍜

A modern, QR-based digital ordering system designed for restaurants to streamline the dining experience. Customers can scan a QR code at their table to browse the menu, place orders, and track status in real-time, while admins manage everything from a powerful dashboard.

## 🌟 Key Features

### 🛒 Customer Experience
- **QR-Based Navigation**: Instant access to the menu by scanning a table-specific QR code.
- **Smart Menu**: Categorized menu items with "Popular" tags and availability status.
- **Dynamic Cart**: Animated "sliding" cart button that collapses on scroll to stay out of the way.
- **Order Tracking**: Dedicated "My Orders" tab to monitor order history and real-time status.
- **Live Notifications**: Instant pop-up alerts when order status changes (e.g., "Ready to serve!").
- **Optional Reviews**: Customers can choose to rate their experience after placing an order.

### 🔐 Admin Management
- **Dashboard & Analytics**: Real-time statistics on today's revenue, total revenue, and popular items.
- **Order Flow Control**: Update order status (Pending -> Confirmed -> Preparing -> Ready -> Completed).
- **Menu Management**: Full CRUD operations for menu items and categories.
- **Secure Access**: Protected admin panel with authentication and session management.
- **Statistics Reset**: Ability to clear/archive data to start a new business cycle.

## 🛠 Tech Stack
- **Frontend**: Flutter Web (Material 3, Google Fonts).
- **Backend**: Dart Shelf (RESTful API).
- **Database**: SQLite (Local persistence).
- **Deployment**: Automatic IP detection for local network hosting.

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel)
- [Dart SDK](https://dart.dev/get-dart)
- SQLite3 (Included in the project)

### Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/hungdaden/on_seat_order.git
   cd on_seat_order
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Build the Web Application**:
   ```bash
   flutter build web
   ```

## 🏗 Operations (Scripts)

We provide handy scripts to manage the system easily:

### 1. Start/Stop Server
Use the `sv.bat` script to manage the backend:
- **Open Server**: `.\sv.bat opensv` (Starts on port 8080).
- **Close Server**: `.\sv.bat closesv` (Kills any process on port 8080).

### 2. Generate QR Codes
Use the `genqr.bat` script to create QR codes for your tables:
- **Auto IP Detection**: `.\genqr.bat currentip` (Detects your current WiFi IP and generates codes).
- **Custom IP**: `.\genqr.bat 192.168.1.10` (Generates codes for a specific static IP).

## 🔑 Admin Access
- **URL**: `http://<your-ip>:8080/admin`
- **Default Username**: `admin`
- **Default Password**: `pho2025`

## 📁 Project Structure
- `/lib`: Flutter frontend source code.
- `/server`: Dart backend and API routes.
- `/web`: Static web assets and built files.
- `onseat_order.db`: SQLite database file (generated on first run).

---
*Developed with ❤️*
