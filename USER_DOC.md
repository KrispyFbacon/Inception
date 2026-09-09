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