const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function main() {
  console.log("Seeding database with sample data...");

  // Create roles
  const roles = ['admin', 'faculty', 'student', 'parent'];
  for (const r of roles) {
    await prisma.role.upsert({
      where: { name: r },
      update: {},
      create: { name: r },
    });
  }

  const adminRole = await prisma.role.findUnique({ where: { name: 'admin' } });
  const facultyRole = await prisma.role.findUnique({ where: { name: 'faculty' } });
  const studentRole = await prisma.role.findUnique({ where: { name: 'student' } });

  // Password for everyone
  const defaultPassword = await bcrypt.hash('admin123', 10);
  const facultyPassword = await bcrypt.hash('faculty123', 10);
  const studentPassword = await bcrypt.hash('student123', 10);

  // 1. Admin
  await prisma.user.upsert({
    where: { email: 'admin@example.com' },
    update: {},
    create: {
      email: 'admin@example.com',
      password: defaultPassword,
      name: 'Super Admin',
      roleId: adminRole.id,
    }
  });

  // 2. Faculty
  const faculty1User = await prisma.user.upsert({
    where: { email: 'faculty1@example.com' },
    update: {},
    create: {
      email: 'faculty1@example.com',
      password: facultyPassword,
      name: 'Dr. Mehta',
      roleId: facultyRole.id,
      facultyProfile: {
        create: { name: 'Dr. Mehta', department: 'Computer Science' }
      }
    }
  });
  
  const faculty2User = await prisma.user.upsert({
    where: { email: 'faculty2@example.com' },
    update: {},
    create: {
      email: 'faculty2@example.com',
      password: facultyPassword,
      name: 'Prof. Sharma',
      roleId: facultyRole.id,
      facultyProfile: {
        create: { name: 'Prof. Sharma', department: 'Mathematics' }
      }
    }
  });

  const faculty1 = await prisma.faculty.findUnique({ where: { userId: faculty1User.id } });
  const faculty2 = await prisma.faculty.findUnique({ where: { userId: faculty2User.id } });

  // 3. Subjects
  const subjCS = await prisma.subject.create({ data: { name: 'Computer Science' } });
  const subjPhy = await prisma.subject.create({ data: { name: 'Physics' } });
  const subjMath = await prisma.subject.create({ data: { name: 'Mathematics' } });
  const subjChem = await prisma.subject.create({ data: { name: 'Chemistry' } });

  // 4. Classes
  const class1 = await prisma.class.create({
    data: {
      name: 'BTech CS - A',
      facultyId: faculty1.id,
      subjects: {
        create: [
          { subjectId: subjCS.id },
          { subjectId: subjPhy.id }
        ]
      }
    }
  });

  const class2 = await prisma.class.create({
    data: {
      name: 'BTech Maths - A',
      facultyId: faculty2.id,
      subjects: {
        create: [
          { subjectId: subjMath.id },
          { subjectId: subjChem.id }
        ]
      }
    }
  });

  const studentNames = [
    "Aarav Patel", "Diya Sharma", "Vihaan Singh", "Aditi Gupta", "Rahul Kumar",
    "Priya Reddy", "Arjun Das", "Neha Verma", "Rohan Joshi", "Kriti Desai"
  ];

  // 5. Students
  for (let i = 1; i <= 5; i++) {
    const studentName = studentNames[i - 1];
    await prisma.user.create({
      data: {
        email: `student${i}@example.com`,
        password: studentPassword,
        name: studentName,
        roleId: studentRole.id,
        studentProfile: {
          create: { 
            name: studentName, 
            enrollmentNo: `ENR00${i}`,
            classId: class1.id
          }
        }
      }
    });
  }

  for (let i = 6; i <= 10; i++) {
    const studentName = studentNames[i - 1];
    await prisma.user.create({
      data: {
        email: `student${i}@example.com`,
        password: studentPassword,
        name: studentName,
        roleId: studentRole.id,
        studentProfile: {
          create: { 
            name: studentName, 
            enrollmentNo: `ENR00${i}`,
            classId: class2.id
          }
        }
      }
    });
  }

  console.log("Seeding complete!");
  console.log("Try logging into the app with:");
  console.log("Faculty: faculty1@example.com / faculty123");
  console.log("Student: student1@example.com / student123");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
