# 📡 Backend API Documentation — Smart Attendee (SIH 2025)

This document describes the backend REST API routes used by the Smart Attendee mobile application.

The backend is built with **Express.js + PostgreSQL** and hosted on Render.

---

## 🔐 Authentication

### **POST /auth/login**
Authenticates student/faculty and returns JWT.

**Body:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "token": "jwt-token",
  "role": "student | faculty"
}
```

---

## 👤 Profile

### **GET /auth/profile**
Fetch authenticated user profile.

Headers:
```
Authorization: Bearer <token>
```

---

## 🧑‍🏫 Faculty Attendance Controls

### **POST /attendance/generate-qr**
Creates a new attendance session & generates a time-limited QR.

**Body:**
```json
{
  "classId": "string",
  "subjectId": "string",
  "location": { "lat": 00.0000, "lng": 00.0000 }
}
```

---

### **POST /attendance/end-session**
Ends current attendance session.

**Body:**
```json
{
  "sessionId": "string"
}
```

---

## 👨‍🎓 Student Attendance

### **POST /attendance/mark-attendance**
Marks attendance after QR scan + geolocation validation.

**Body:**
```json
{
  "sessionId": "string",
  "location": { "lat": 00.000, "lng": 00.000 }
}
```

---

## 📊 Analytics

### **GET /analytics/faculty**
Returns class-wise & subject-wise analytics for faculty.

---

### **GET /analytics/student**
Returns personal attendance stats for a student.

---

This documentation is safe to share publicly and contains **no sensitive keys, passwords, or backend internals.**