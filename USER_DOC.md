### Verifying the setup
 
```bash
docker ps               # check that all containers are Up
docker network ls       # inception network should be listed
docker volume ls        # wordpress data + db data volumes should be listed
```


DEV_DOC.md
│
├── 1. Environment Setup
│   ├── Prerequisites
│   ├── Configuration
│   └── Secrets
│
├── 2. Build and Launch
│   ├── Makefile
│   └── Docker Compose
│
├── 3. Data Persistence
│   └── Volumes / DATA_PATH
│
├── 4. Credentials
│
├── 5. Container Management
│   ├── Status
│   ├── Logs
│   ├── Exec
│   └── Inspect
│
├── 6. Testing & Verification
│   ├── Containers
│   ├── HTTPS/TLS
│   ├── Network
│   ├── Ports
│   └── Persistence
│
└── 7. Troubleshooting


# Inception — Developer Documentation

## 1. Environment Setup
### 1.1 Prerequisites
### 1.2 Project Structure
### 1.3 Configuration
### Example .env Configuration
### 1.4 Changing the Domain
### 1.5 Changing the Data Location
### 1.6 Docker Secrets

## 2. Build and Launch
### 2.1 Build and Start
### 2.2 Stop the Project
### 2.3 Rebuild the Project
### 2.4 View Logs

## 3. Project Management
### 3.1 Makefile Commands

## 4. Testing
### 4.1 Check Containers
### 4.2 Test HTTPS
### 4.3 Test Persistence

## 5. Troubleshooting
### MariaDB is restarting
### WordPress cannot connect to MariaDB
### Site is not reachable
### Certificate warning