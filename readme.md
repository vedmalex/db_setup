# MongoDB Database Setup Guide

This repository provides tools and scripts for setting up and managing MongoDB databases with backup and restore capabilities.

## Prerequisites
- Git
- Docker and Docker Compose
- Basic understanding of MongoDB
- Access to edit system files (for /etc/hosts modification)

## Installation

1. **Clone the Repository**:
   ```bash
   git clone git@github.com:vedmalex/db_setup.git
   cd db_setup
   ```

2. **Create Backup Directory**:
   ```bash
   mkdir dump
   ```
   The `dump` directory is used to store database backups. Each database can have special control files:
   - `.skip_dump` - Skip this database during backup operations
   - `.skip_restore` - Skip this database during restore operations
   - `.dumped` - Indicates successful backup completion
   - `.restored` - Indicates successful restore completion

3. **Configure Environment Variables**:
   ```bash
   cp env.sample .env
   ```
   Edit `.env` file to set your credentials:
   ```bash
   MONGO_ROOT_USERNAME=<your_username>
   MONGO_ROOT_PASSWORD=<your_secure_password>
   ```

4. **Update Hosts File**:
   Add these entries to your `/etc/hosts` file:
   ```bash
   127.0.0.1 mongo1
   127.0.0.1 mongo2
   ```

5. **User Management**:
   - Root user credentials are set in the `.env` file
   - Additional users can be added in `scripts/users.json`
   - Use `scripts/users.sample.json` as a template for user configuration

6. **Start the Deployment**:
   ```bash
   ./init.sh
   ```

7. **Connect to MongoDB**:
   Use this connection string format:
   ```
   mongodb://<username>:<password>@mongo1:27017/<database>?authSource=admin&replicaSet=rs0
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

Let me know if you'd like me to add any additional sections or details to the README, such as:
- Detailed backup/restore procedures
- Troubleshooting guide
- System requirements
- Configuration options
- Usage examples