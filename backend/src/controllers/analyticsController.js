const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const getStudentAnalytics = async (req, res) => {
  try {
    const userId = req.user.userId;
    const student = await prisma.student.findUnique({
      where: { userId },
      include: {
        class: {
          include: { subjects: { include: { subject: true } } }
        },
        attendanceRecords: true
      }
    });

    if (!student) {
      return res.status(404).json({ message: "Student profile not found" });
    }

    if (!student.class) {
      return res.json({
        studentId: student.id,
        studentName: student.name,
        overall: { totalSessions: 0, totalPresent: 0, totalAbsent: 0, attendancePct: 0 },
        subjects: []
      });
    }

    // Basic logic to construct analytics from attendance records
    const records = student.attendanceRecords;
    const totalPresent = records.filter(r => r.status === 'present').length;
    
    // We would normally count total QRSessions for this class to know how many they missed
    const allSessions = await prisma.qRSession.findMany({
      where: { classId: student.classId }
    });
    
    const totalSessions = allSessions.length;
    const totalAbsent = totalSessions - totalPresent;
    const attendancePct = totalSessions > 0 ? (totalPresent / totalSessions * 100).toFixed(2) : 0;

    let subjectsData = [];
    for (const cs of student.class.subjects) {
      const subjSessions = allSessions.filter(s => s.subjectId === cs.subjectId).length;
      const subjPresent = records.filter(r => r.subjectId === cs.subjectId && r.status === 'present').length;
      const subjPct = subjSessions > 0 ? (subjPresent / subjSessions * 100).toFixed(2) : 0;
      
      subjectsData.push({
        subjectId: cs.subjectId,
        subjectName: cs.subject.name,
        totalSessions: subjSessions,
        presentCount: subjPresent,
        absentCount: subjSessions - subjPresent,
        attendancePct: parseFloat(subjPct)
      });
    }

    res.json({
      studentId: student.id,
      studentName: student.name,
      classId: student.classId,
      className: student.class.name,
      overall: {
        totalSessions,
        totalPresent,
        totalAbsent,
        attendancePct: parseFloat(attendancePct)
      },
      subjects: subjectsData
    });
  } catch (error) {
    console.error("Student Analytics Error:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

const getFacultyAnalytics = async (req, res) => {
  try {
    const userId = req.user.userId;
    const faculty = await prisma.faculty.findUnique({
      where: { userId },
      include: {
        classes: {
          include: {
            students: true,
            subjects: { include: { subject: true } },
            qrSessions: { include: { attendanceRecords: true } }
          }
        }
      }
    });

    if (!faculty) {
      return res.status(404).json({ message: "Faculty profile not found" });
    }

    // Simplified aggregation
    let classesData = [];
    for (const cls of faculty.classes) {
      const totalStudents = cls.students.length;
      const totalSessions = cls.qrSessions.length;
      
      let presentCount = 0;
      cls.qrSessions.forEach(session => {
        presentCount += session.attendanceRecords.filter(r => r.status === 'present').length;
      });
      
      const possibleSeats = totalSessions * totalStudents;
      const attendancePct = possibleSeats > 0 ? (presentCount / possibleSeats * 100).toFixed(2) : 0;

      classesData.push({
        classId: cls.id,
        className: cls.name,
        totalStudents,
        overall: {
          totalSessions,
          presentCount,
          possibleSeats,
          attendancePct: parseFloat(attendancePct)
        },
        subjects: cls.subjects.map(cs => ({
          subjectId: cs.subjectId,
          subjectName: cs.subject.name
        })) // Simplified subject list
      });
    }

    res.json({
      facultyId: faculty.id,
      facultyName: faculty.name,
      generatedAt: new Date().toISOString(),
      classes: classesData
    });

  } catch (error) {
    console.error("Faculty Analytics Error:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

module.exports = {
  getStudentAnalytics,
  getFacultyAnalytics
};
