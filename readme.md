# how to use

## 1. git clone repository

## 2. create folders for dump

```mkdir dump```

put here all databases you want to backup

special files
 - .skip_dump - skip db from being dumped to backup folder
 - .skip_restore - skip db from being restored from backup folder
 - .dumped - db successfully dumped to backup folder
 - .restored - db successfully restored from backup folder

## 3. configure env file

```cp env.sample .env```

## 4. configure /etc/hosts file

add this code to the end of the file:

```bash
127.0.0.1 mongo1
127.0.0.1 mongo2
```

## 5. for adding user to the db

change the password in the .env file

```bash
MONGO_ROOT_USERNAME=< super fancy username >
MONGO_ROOT_PASSWORD=< super fancy root password >
```
additional users can be added to the `scripts/users.json` file
see the example in the file `scripts/users.sample.json`


5. run start deployment

```./init.sh```

6. for connection db

```
mongodb://<super fancy username>:<super fancy root password>@mongo1:27017/<dtabase name>?authSource=admin&replicaSet=rs0
```

pull requests is welcome