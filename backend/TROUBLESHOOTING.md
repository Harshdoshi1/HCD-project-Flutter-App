# Troubleshooting Guide - Connection Issues

## 🚨 Problem: ERR_CONNECTION_REFUSED

The error `ERR_CONNECTION_REFUSED` means the backend server is not running or not accessible.

## 🔍 Step-by-Step Diagnosis

### 1. Check if Backend Server is Running

```bash
cd backend
npm start
```

**Expected Output:**
```
✅ Server started successfully on port 5001
🌐 Server URL: http://localhost:5001
🔍 Test endpoint: http://localhost:5001/api/test
💚 Health check: http://localhost:5001/api/health
```

**If you see errors, continue to step 2.**

### 2. Test Database Connection

```bash
cd backend
node test-db-connection.js
```

**Expected Output:**
```
✅ Database connection successful
✅ Query test successful
✅ Target database exists
```

**If database connection fails, continue to step 3.**

### 3. Check Database Status

#### For Windows:
```bash
# Check if MySQL service is running
services.msc
# Look for "MySQL" service and ensure it's "Running"
```

#### For macOS:
```bash
# Check if MySQL is running
brew services list | grep mysql
# Start MySQL if not running
brew services start mysql
```

#### For Linux:
```bash
# Check MySQL status
sudo systemctl status mysql
# Start MySQL if not running
sudo systemctl start mysql
```

### 4. Verify Database Configuration

Create a `.env` file in the `backend` folder:

```bash
cd backend
# Copy the template
cp env-template.txt .env
# Edit the file with your database credentials
nano .env
```

**Example .env content:**
```env
DB_NAME=hcd
DB_USER=root
DB_PASSWORD=your_actual_password
DB_HOST=localhost
DB_PORT=3306
PORT=5001
NODE_ENV=development
```

### 5. Test Server Without Database

```bash
cd backend
node start-server.js
```

This will start the server even if the database is not accessible.

## 🛠️ Common Solutions

### Solution 1: MySQL Not Running
```bash
# Windows
net start mysql

# macOS
brew services start mysql

# Linux
sudo systemctl start mysql
```

### Solution 2: Database Doesn't Exist
```sql
-- Connect to MySQL as root
mysql -u root -p

-- Create database
CREATE DATABASE hcd;

-- Verify
SHOW DATABASES;
```

### Solution 3: Wrong Credentials
```sql
-- Connect to MySQL as root
mysql -u root -p

-- Create user with proper permissions
CREATE USER 'hcd_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON hcd.* TO 'hcd_user'@'localhost';
FLUSH PRIVILEGES;
```

### Solution 4: Port Already in Use
```bash
# Check what's using port 5001
netstat -ano | findstr :5001

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

## 🧪 Testing Steps

### 1. Test Basic Server
```bash
curl http://localhost:5001/api/test
# Should return: {"message":"Server is running!","timestamp":"..."}
```

### 2. Test Health Check
```bash
curl http://localhost:5001/api/health
# Should return: {"status":"OK","timestamp":"..."}
```

### 3. Test Database Endpoints
```bash
curl http://localhost:5001/api/batches/getAllBatches
# Should return data or proper error message
```

## 📋 Checklist

- [ ] MySQL service is running
- [ ] Database 'hcd' exists
- [ ] User has proper permissions
- [ ] .env file is configured correctly
- [ ] Backend server starts without errors
- [ ] Port 5001 is not blocked
- [ ] CORS is properly configured
- [ ] Frontend can reach localhost:5001

## 🆘 Still Having Issues?

### Check Logs
```bash
cd backend
npm start 2>&1 | tee server.log
```

### Check Network
```bash
# Test if port is accessible
telnet localhost 5001

# Check firewall settings
# Windows: Windows Defender Firewall
# macOS: System Preferences > Security & Privacy > Firewall
# Linux: ufw or iptables
```

### Alternative Port
If port 5001 is blocked, change it in `.env`:
```env
PORT=3001
```

Then update frontend API calls to use the new port.

## 📞 Support

If you're still experiencing issues:
1. Check the server logs for specific error messages
2. Verify your MySQL installation and credentials
3. Ensure no other services are using port 5001
4. Check if your antivirus/firewall is blocking the connection
