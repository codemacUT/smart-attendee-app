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
  "classId": 1,
  "subjectId": 10,
  "geoLat": 0.0000,
  "geoLng": 0.0000
}
```

---

### **POST /attendance/end-session**
Ends current attendance session.

**Body:**
```json
{
  "sessionId": 1
}
```

---

### **GET /attendance/session/:id/stats**
[NEW] Returns the exact breakdown of present and absent students for a specific session to power the Session Complete Card.

**Response:**
```json
{
  "presentCount": 1,
  "totalCount": 5,
  "presentStudents": [
    {"id":1, "name":"Student 1", "enrollmentNo":"ENR001", "time":"2026-07-19T16:09:18.535Z"}
  ],
  "absentStudents": [
    {"id":2, "name":"Student 2", "enrollmentNo":"ENR002"}
  ]
}
```

---

## 👨‍🎓 Student Attendance

### **POST /attendance/mark-attendance**
Marks attendance after QR scan + geolocation validation.

**Body:**
```json
{
  "qrSessionId": 1,
  "geoLat": 0.0000,
  "geoLng": 0.0000
}
```

---

## 📊 Analytics

### **GET /analytics/faculty**
Returns class-wise & subject-wise analytics for faculty.

**Response:**
```json
{
  "facultyId": 1,
  "facultyName": "Dr. Mehta",
  "generatedAt": "2026-07-19T16:08:03.345Z",
  "classes": [
    {
      "classId": 1,
      "className": "BSc CS - A",
      "totalStudents": 5,
      "overall": {
        "totalSessions": 12,
        "presentCount": 45,
        "possibleSeats": 60,
        "attendancePct": 75.00
      },
      "subjects": [
        {
          "subjectId": 10,
          "subjectName": "Computer Science"
        }
      ]
    }
  ]
}
```

---

### **GET /analytics/student**
Returns personal attendance stats for a student.

**Response:**
```json
{
  "studentId": 1,
  "studentName": "Student 1",
  "classId": 1,
  "className": "BSc CS - A",
  "overall": {
    "totalSessions": 12,
    "totalPresent": 9,
    "totalAbsent": 3,
    "attendancePct": 75.00
  },
  "subjects": [
    {
      "subjectId": 10,
      "subjectName": "Computer Science",
      "totalSessions": 6,
      "presentCount": 5,
      "absentCount": 1,
      "attendancePct": 83.33
    }
  ]
}
```

---

This documentation is safe to share publicly and contains **no sensitive keys, passwords, or backend internals.**