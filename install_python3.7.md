## 安装python3.7
wget --no-check-certificate https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tgz
tar -zxvf Python-3.7.0.tgz

### 需要对python3.5进行重新编译安装。
```
yum install -y zlib-devel openssl-devel libffi-devel zip unzip make gcc*
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/libffi-devel-3.0.13-18.el7.x86_64.rpm
rpm -ivh libffi-devel-3.0.13-18.el7.x86_64.rpm

cd Python-3.7.0
./configure --prefix=/usr/local/python3.7 --enable-shared
make & make install
cp -R /usr/local/python3.7/lib/* /usr/lib64/
ln -s /usr/local/python3.7/bin/python3 /usr/bin/python3
```


## 安装pip以及setuptools
```
wget --no-check-certificate  https://files.pythonhosted.org/packages/ef/1d/201c13e353956a1c840f5d0fbf0461bd45bbd678ea4843ebf25924e8984c/setuptools-40.2.0.zip
> 47881d54ede4da9c15273bac65f9340f8929d4f0213193fa7894be384f2dcfa6
unzip setuptools-40.2.0.zip
cd setuptools-40.2.0
python3 setup.py build
python3 setup.py install

### 报错： RuntimeError: Compression requires the (missing) zlib module
### 我们需要在linux中安装zlib-devel包，进行支持。
```

## 安装pip
```
wget --no-check-certificate  https://files.pythonhosted.org/packages/69/81/52b68d0a4de760a2f1979b0931ba7889202f302072cc7a0d614211bc7579/pip-18.0.tar.gz
> a0e11645ee37c90b40c46d607070c4fd583e2cd46231b1c06e389c5e814eed76
tar -zxvf pip-18.0.tar.gz
cd pip-18.0
python3 setup.py build
python3 setup.py install

### python3 -m pip install paramiko
### 报错 ImportError: cannot import name 'HTTPSHandler'
### 根据老衲多年的经验，应该是缺少openssl的开发环境，我们继续安装
```
