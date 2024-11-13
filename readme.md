# run compose

folder structure
```bash
/ --> docker-compose.yaml
/dump --> folder with dumps
/config --> folder with config files
```

mongodb://localhost:27017,localhost:27018,localhost:27019/?replicaSet=rs0

## настройи хоста базы данных

необходимо сконфигурировать /etc/hosts для доступа к базе данных из контейнера
``` bash
sudo nano /etc/hosts
```
добавить в конец файла текст

```bash
127.0.0.1 mongo1
127.0.0.1 mongo2
```

## восстановление базы данных из резервной копии

в папку с docker-compose.yaml создать папку dump
в нее переместить все необходимые базы данных для восстановления в контейнер

запустить контейнер с командой
```
docker-compose up -d
```
выполнить иморт данных

```
mongorestore --uri "mongodb://localhost:27017,localhost:27017,localhost:27017/dbname?replicaSet=rs0"
```