# How to Use

## Getting Started

1. **Git Clone Repository**:
   - Clone the repository to your local machine.

2. **Create Folders for Dump**:
   - Create a `dump` folder in the project directory.
   - This is where all the databases you want to backup will be stored.

   Special files:
   - `.skip_dump`: Add this file to a database folder to skip it from being dumped to the backup folder.
   - `.skip_restore`: Add this file to a database folder to skip it from being restored from the backup folder.
   - `.dumped`: This file is created when a database is successfully dumped to the backup folder.
   - `.restored`: This file is created when a database is successfully restored from the backup folder.

3. **Configure Environment File**:
   - Copy the `env.sample` file and rename it to `.env`.
   - This file contains the environment variables needed for the application.

4. **Configure `/etc/hosts` File**:
   - Add the following lines to the end of the `/etc/hosts` file:
     ```
     127.0.0.1 mongo1
     127.0.0.1 mongo2
     ```
   - This allows the application to connect to the MongoDB instances.

5. **Adding Users to the Database**:
   - Change the password in the `.env` file for the `MONGO_ROOT_USERNAME` and `MONGO_ROOT_PASSWORD` variables.
   - Additional users can be added to the `scripts/users.json` file. See the example in the `scripts/users.sample.json` file.

6. **Run the Deployment**:
   - Execute the `./init.sh` script to start the deployment.

7. **Connecting to the Database**:
   - Use the following connection string to connect to the database:
     ```
     mongodb://<super fancy username>:<super fancy root password>@mongo1:27017/<database name>?authSource=admin&replicaSet=rs0
     ```

We welcome pull requests to help improve the project!