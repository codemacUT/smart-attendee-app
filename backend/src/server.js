const express = require('express');
const cors = require('cors');
const { authenticateToken, permit } = require('./middlewares/authMiddleware');
const authController = require('./controllers/authController');
const attendanceController = require('./controllers/attendanceController');
const analyticsController = require('./controllers/analyticsController');

const app = express();
app.use(cors());
app.use(express.json());

// Auth Routes
app.post('/auth/register', authController.register);
app.post('/auth/login', authController.login);
app.get('/auth/profile', authenticateToken, authController.getProfile);

// Attendance Routes
app.post('/attendance/generate-qr', authenticateToken, permit('faculty'), attendanceController.generateQR);
app.post('/attendance/mark-attendance', authenticateToken, permit('student'), attendanceController.markAttendance);
app.post('/attendance/end-session', authenticateToken, permit('faculty'), attendanceController.endSession);
app.get('/attendance/session/:id', authenticateToken, permit('faculty'), attendanceController.getSessionDetails);
app.get('/attendance/session/:id/stats', authenticateToken, permit('faculty'), attendanceController.getSessionStats);

// Analytics Routes
app.get('/analytics/student', authenticateToken, permit('student'), analyticsController.getStudentAnalytics);
app.get('/analytics/faculty', authenticateToken, permit('faculty'), analyticsController.getFacultyAnalytics);

app.get('/', (req, res) => {
  res.send('Smart Attendee Backend API is running!');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is listening on port ${PORT}`);
});
