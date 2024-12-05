# requirements

- domain name
- app running
- TLS + HTTPS + autorenewal + auto-redirect
- openssh haroended to app
- firewall
- load balancer + health checks
- automated deployment
- monitoring - web site availability


## steps

### create user and add to sudo group
- add user
  `adduser app`
- add user to sudo group
  `usermod -aG sudo app`
- check if user is in sudo group
  `su app`
  `sudo ls` тto check if user is in sudo group

### install tmux
- `sudo apt-get install tmux`
- check if tmux is installed
  `tmux ls`

  tmux keyboard shortcuts:
  - `Ctrl+b` then `d` to detach session
  - `Ctrl+b` then `"` to split window horizontally
  - `Ctrl+b` then `%` to split window vertically
  - `Ctrl+b` then `o` to switch to next window
  - `Ctrl+b` then `c` to create new window
  - `Ctrl+b` then `n` to switch to next session
  - `Ctrl+b` then `p` to switch to previous session
  - `Ctrl+b` then `?` to show help

to create session with name:
- `tmux new -s session_name`
to attach to session:
- `tmux attach -t session_name`

 более подробно настройки TMUX https://youtu.be/DzNmUNvnB04

### remove password authentication from ssh

ensure that ssh is configured to allow public key authentication only.

- add your own public key to app user authorized_keys file:
  on local machine:
  `ssh-keygen`
  `cat ~/.ssh/id_rsa.pub`
  copy and paste the output to your app user authorized_keys file:
  `sudo nano /home/app/.ssh/authorized_keys`

  or use ssh-copy-id:
  `ssh-copy-id app@your_server_ip`
  enter your password when prompted

  - disable password authentication in sshd_config:
  - `sudo nano /etc/ssh/sshd_config`
  - change `PasswordAuthentication yes` to `PasswordAuthentication no`
  - change petmit to login as root user
  - `sudo nano /etc/ssh/sshd_config`
  - change `PermitRootLogin yes` to `PermitRootLogin no`
  - disable use PAM authentication for ssh login:
  - `sudo nano /etc/ssh/sshd_config`
  - change `UsePAM yes` to `UsePAM no`

  findout any password authentication enabled in hosting provide files and disable it

  - restart ssh service:
  - `sudo systemctl restart ssh`

additional security measures:
- rename ssh port from 22 to <anything else>:


### register domain name
- register domain name at namecheap.com
- add DNS records to point domain name to server IP address
- wait for DNS records to propagate
- check if domain name is working by visiting it in a web browser
- `nslookup domain_name` to check DNS records
- `ping domain_name` to check if server is responding to pings
- `dig domain_name` to check DNS records and server response time


# setup docker
- install docker:
- `sudo apt-get update`
- `sudo apt-get install docker.io`
- `sudo systemctl start docker`
- `sudo systemctl enable docker`
- check if docker is running:
- `sudo docker ps`

  add app user to docker group:
- `sudo usermod -aG docker app`


для конфигурирования паролей можно использовать docker compose secrets через файлы или переменные окружения.


поскольку docker по умолчанию открывает порты которые expose в контейнерах, то для обеспечения безопасности необходимо ограничить доступ к ним используя traefic


```

# setup nginx