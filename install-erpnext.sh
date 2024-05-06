echo "setting up frappe bench user"
sudo adduser $1
usermod -aG sudo $1
su $1
cd /home/$1/


sudo apt-get update -y
sudo apt-get upgrade -y

echo "installing git..."
sudo apt-get install git -y

echo "installing python deps..."
sudo apt-get install python3-dev python3.10-dev python3-setuptools python3-pip python3-distutils -y

echo "installing python virtual env..."
sudo apt-get install python3.10-venv -y

echo "installing other deps..."
sudo apt-get install software-properties-common -y

echo "installing mariadb..."
sudo apt install mariadb-server mariadb-client -y

echo "installing redis-server..."
sudo apt-get install redis-server -y

echo "installing other deps..."
sudo apt-get install xvfb libfontconfig wkhtmltopdf -y
sudo apt-get install libmysqlclient-dev -y

echo "setting up mariadb..."
sudo mysql_secure_installation

echo "adding configurations to my.cnf..."
SQL_CONFIG="/etc/mysql/my.cnf"

# Check if the MySQL configuration file exists
if [ -f "$SQL_CONFIG" ]; then
            # Append the required configuration to the file
                echo -e "\n[mysqld]\ncharacter-set-client-handshake = FALSE\ncharacter-set-server = utf8mb4\ncollation-server = utf8mb4_unicode_ci\n\n[mysql]\ndefault-character-set = utf8mb4" >> $SQL_CONFIG
                echo "Configuration has been appended successfully."
            else
                echo "Error: MySQL configuration file does not exist."
fi

echo "restarting mariadb..."
sudo service mysql restart

echo "installing curl..."
sudo apt install curl -y

echo "installing nvm..."
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

source ~/.profile

nvm install 18

nvm use 18

echo "installing npm..."
sudo apt-get install npm -y

echo "installing yarn..."
sudo npm install -g yarn -y

echo "installing frappe-bench..."

pip3 install frappe-bench

cd $HOME

echo "init new bench..."
bench init --frappe-branch version-15 frappe-bench

cd frappe-bench

chmod -R o+rx /home/$1/

echo "creating new master dev scic site..."
bench new-site master-dev.scic

echo "getting required apps..."
bench get-app --branch version-15 erpnext

bench get-app https://github.com/Raya-Solutions/SCIC.git

echo "installing apps..."
bench --site master-dev.scic install-app erpnext

bench --site master-dev.scic install-app scic

echo "setting up production..."
bench --site master-dev.scic enable-scheduler

bench --site master-dev.scic set-maintenance-mode off

sudo bench setup production $1

bench setup nginx

sudo supervisorctl restart all
sudo bench setup production $1

echo "opening up ports..."
sudo ufw allow 22,25,143,80,443,3306,3022,8000/tcp
sudo ufw enable

echo "setting up custom domain"
bench config dns_multitenant on

bench setup add-domain main-dev.scictech.xyz --site master-dev.scic

bench setup nginx

sudo service nginx reload

sudo snap install core

sudo snap refresh core

sudo snap install --classic certbot

sudo ln -s /snap/bin/certbot /usr/bin/certbot

sudo certbot --nginx
