const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key_here';

const register = async (req, res) => {
  try {
    const { email, password, name, Role } = req.body;
    
    if (!email || !password || !name || !Role) {
      return res.status(400).json({ message: "All fields are required" });
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: "Email already registered" });
    }

    const roleRecord = await prisma.role.findUnique({ where: { name: Role } });
    if (!roleRecord) {
      return res.status(400).json({ message: "Invalid role" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
        roleId: roleRecord.id
      }
    });

    // In a real app, you would also create the corresponding Student/Faculty/Parent profile here
    // based on the role, or do it in an onboarding step.

    res.status(201).json({ message: "User registered successfully" });
  } catch (error) {
    console.error("Register Error:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password required" });
    }

    const user = await prisma.user.findUnique({ 
      where: { email },
      include: { role: true }
    });

    if (!user) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    const token = jwt.sign(
      { userId: user.id, role: user.role.name },
      JWT_SECRET,
      { expiresIn: '1h' }
    );

    res.json({ token, role: user.role.name });
  } catch (error) {
    console.error("Login Error:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

const getProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const roleName = req.user.role;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        studentProfile: true,
        facultyProfile: true,
        parentProfile: true,
      }
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    let profileData = {
      id: user.id,
      email: user.email,
      role: roleName,
      name: user.name // fallback name
    };

    if (roleName === 'student' && user.studentProfile) {
      profileData.name = user.studentProfile.name;
    } else if (roleName === 'faculty' && user.facultyProfile) {
      profileData.name = user.facultyProfile.name;
    } else if (roleName === 'parent' && user.parentProfile) {
      profileData.name = user.parentProfile.name;
    } else if (roleName === 'admin') {
      profileData.name = user.name || 'Admin';
    } else {
      profileData.name = null; // No profile created yet
    }

    res.json(profileData);
  } catch (error) {
    console.error("Profile Error:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

module.exports = {
  register,
  login,
  getProfile
};
