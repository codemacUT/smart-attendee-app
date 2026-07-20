const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Haversine formula
function getDistanceFromLatLonInMeters(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth radius in meters
  const p1 = (lat1 * Math.PI) / 180;
  const p2 = (lat2 * Math.PI) / 180;
  const dp = ((lat2 - lat1) * Math.PI) / 180;
  const dl = ((lon2 - lon1) * Math.PI) / 180;
  
  const a = Math.sin(dp / 2) * Math.sin(dp / 2) +
            Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) * Math.sin(dl / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

const generateQR = async (req, res) => {
  try {
    const userId = req.user.userId; // user is faculty
    const { classId, subjectId, geoLat, geoLng } = req.body;

    if (!classId || !subjectId || geoLat === undefined || geoLng === undefined) {
      return res.status(400).json({ message: "classId, subjectId, geoLat, geoLng are required" });
    }

    const faculty = await prisma.faculty.findUnique({ where: { userId } });
    if (!faculty) {
      return res.status(403).json({ message: "Faculty profile not found" });
    }
    const facultyId = faculty.id;

    // Check if this faculty teaches this class
    const facultyClass = await prisma.class.findFirst({
      where: {
        id: parseInt(classId),
        facultyId: facultyId
      },
      include: { subjects: true }
    });

    if (!facultyClass) {
      return res.status(403).json({ message: "You are not assigned to this class" });
    }

    // Check subject
    const subjectAssigned = facultyClass.subjects.some(cs => cs.subjectId === parseInt(subjectId));
    if (!subjectAssigned) {
      return res.status(400).json({ message: "Subject is not assigned to this class" });
    }

    // Deactivate previous active QR sessions for this class & subject
    await prisma.qRSession.updateMany({
      where: {
        classId: parseInt(classId),
        facultyId: facultyId,
        subjectId: parseInt(subjectId),
        isActive: true
      },
      data: { isActive: false }
    });

    const newSession = await prisma.qRSession.create({
      data: {
        facultyId,
        classId: parseInt(classId),
        subjectId: parseInt(subjectId),
        geoLat: parseFloat(geoLat),
        geoLng: parseFloat(geoLng),
        isActive: true
      }
    });

    res.json({
      message: "QR session generated successfully",
      qrSessionId: newSession.id,
      generatedAt: newSession.generatedAt
    });

  } catch (error) {
    console.error("Error generating QR:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

const refreshQR = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { qrSessionId } = req.body;

    if (!qrSessionId) {
      return res.status(400).json({ message: "qrSessionId is required" });
    }

    const faculty = await prisma.faculty.findUnique({ where: { userId } });
    if (!faculty) {
      return res.status(403).json({ message: "Faculty profile not found" });
    }

    const session = await prisma.qRSession.findUnique({
      where: { id: parseInt(qrSessionId) }
    });

    if (!session) {
      return res.status(404).json({ message: "QR Session not found" });
    }

    if (session.facultyId !== faculty.id) {
      return res.status(403).json({ message: "You don't have permission to refresh this session" });
    }

    const updatedSession = await prisma.qRSession.update({
      where: { id: session.id },
      data: { generatedAt: new Date() }
    });

    res.json({
      message: "QR session refreshed successfully",
      qrSessionId: updatedSession.id,
      generatedAt: updatedSession.generatedAt
    });

  } catch (error) {
    console.error("Error refreshing QR:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

const markAttendance = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { qrSessionId, geoLat, geoLng } = req.body;

    if (!qrSessionId || geoLat === undefined || geoLng === undefined) {
      return res.status(400).json({ message: "qrSessionId, geoLat, geoLng are required" });
    }

    const session = await prisma.qRSession.findUnique({
      where: { id: parseInt(qrSessionId) },
      include: {
        class: {
          include: { subjects: true }
        }
      }
    });

    if (!session || !session.isActive) {
      return res.status(400).json({ message: "Invalid or expired QR session" });
    }

    const sessionDurationMinutes = 5;
    const sessionExpiry = new Date(session.generatedAt);
    sessionExpiry.setMinutes(sessionExpiry.getMinutes() + sessionDurationMinutes);
    
    if (new Date() > sessionExpiry) {
      return res.status(400).json({ message: "QR session has expired" });
    }

    const student = await prisma.student.findUnique({
      where: { userId }
    });

    if (!student || student.classId !== session.classId) {
      return res.status(403).json({ message: "You are not enrolled in this class" });
    }

    const existingAttendance = await prisma.attendanceRecord.findUnique({
      where: {
        studentId_qrSessionId: {
          studentId: student.id,
          qrSessionId: session.id
        }
      }
    });

    if (existingAttendance) {
      return res.status(400).json({ message: "Attendance already marked" });
    }

    const distance = getDistanceFromLatLonInMeters(parseFloat(geoLat), parseFloat(geoLng), session.geoLat, session.geoLng);
    const allowedDistance = 50; 

    if (distance > allowedDistance) {
      return res.status(400).json({ message: "You are not within the allowed area" });
    }

    const attendance = await prisma.attendanceRecord.create({
      data: {
        studentId: student.id,
        classId: session.classId,
        subjectId: session.subjectId,
        status: "present",
        qrSessionId: session.id
      }
    });

    res.json({ message: "Attendance marked successfully", attendance });

  } catch (error) {
    console.error("Error marking attendance:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

const endSession = async (req, res) => {
  try {
    const { sessionId } = req.body;
    await prisma.qRSession.update({
      where: { id: parseInt(sessionId) },
      data: { isActive: false }
    });
    res.json({ success: true, message: "Session ended successfully" });
  } catch (error) {
    console.error("End session error:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

const getSessionDetails = async (req, res) => {
  try {
    const sessionId = parseInt(req.params.id);
    const session = await prisma.qRSession.findUnique({
      where: { id: sessionId },
      include: {
        attendanceRecords: {
          include: { student: true }
        }
      }
    });

    if (!session) {
      return res.status(404).json({ message: "Session not found" });
    }

    res.json({
      id: session.id,
      isActive: session.isActive,
      generatedAt: session.generatedAt,
      attendance: session.attendanceRecords.map(r => ({
        studentId: r.student.id,
        name: r.student.name,
        enrollmentNo: r.student.enrollmentNo,
        status: r.status,
        datetime: r.datetime
      }))
    });
  } catch (error) {
    console.error("Get Session error:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

const getSessionStats = async (req, res) => {
  try {
    const sessionId = parseInt(req.params.id);
    const session = await prisma.qRSession.findUnique({
      where: { id: sessionId },
      include: {
        class: {
          include: { students: true }
        },
        attendanceRecords: {
          include: { student: true }
        }
      }
    });

    if (!session) {
      return res.status(404).json({ message: "Session not found" });
    }

    const totalStudents = session.class.students.length;
    const presentStudents = session.attendanceRecords.filter(r => r.status === 'present');
    const presentCount = presentStudents.length;

    // Determine absentees
    const presentStudentIds = presentStudents.map(r => r.studentId);
    const absentStudents = session.class.students.filter(s => !presentStudentIds.includes(s.id));

    res.json({
      presentCount,
      totalCount: totalStudents,
      presentStudents: presentStudents.map(r => ({
        id: r.student.id,
        name: r.student.name,
        enrollmentNo: r.student.enrollmentNo,
        time: r.datetime
      })),
      absentStudents: absentStudents.map(s => ({
        id: s.id,
        name: s.name,
        enrollmentNo: s.enrollmentNo
      }))
    });
  } catch (error) {
    console.error("Get Session Stats error:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

module.exports = {
  generateQR,
  refreshQR,
  markAttendance,
  endSession,
  getSessionDetails,
  getSessionStats
};
