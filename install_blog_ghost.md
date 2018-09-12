### 更新系统版本
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo 
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo 
yum makecache  
yum update

### 安装nginx
vi /etc/yum.repo.d/nginx.repo

[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=0
enabled=1

yum install nginx  
systemctl enable nginx  
systemctl start nginx  
ps -ef |grep nginx  

### 配置nginx
vim /etc/nginx/conf.d/blog.conf 
server {  
    listen 80;
    server_name blog.ghost.com // 这里修改为你的域名；如果没有域名，则输入服务器公网 IP 地址;
    location / {
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   Host      $http_host;
        proxy_pass         http://127.0.0.1:2368;
    }
}

### 安装Node.js
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash  
source .bashrc  
nvm ls  
nvm install 4.2  

curl -L https://ghost.org/zip/ghost-latest.zip -o ghost.zip  
unzip -uo  ghost.zip -d /var/www/html/ghost  
chown -R nginx:nginx /var/www/html/ghost/  
cd /var/www/html/ghost/  
npm install --production  
cp config.example.js config.js  
vim config.js  

    production: {
        url: 'http://blog.ghost.com',
        mail: {},
        database: {
            client: 'sqlite3',
            connection: {
                filename: path.join(__dirname, '/content/data/ghost.db')
            },
            debug: false
        },
        server: {
            host: '127.0.0.1',
            port: '2368'
        }
    },

npm install -g pm2  
NODE_ENV=production pm2 start index.js --name "ghost"  
pm2 startup centos  
pm2 save
systemctl reload nginx  

### 测试
首页 http://blog.ghost.com/ghost 
Ghost后台 http://blog.ghost.com/ghost
