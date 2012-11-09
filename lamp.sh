#!/bin/bash
#
#  Web Server Installer
#   2012 cornel ciordache@syntax.net>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

echo "+————————————-+"
echo "| Web Server Installer                |"
echo "| Automatically Configure and Build : |"
echo "| Apache                              |"
echo "| mySQL                               |"
echo "| PHP                                 |"
echo "+————————————-+"
echo ""

if [ "$(whoami)" != ‘root’ ]; then
        echo "You must be root to run this script"
#       exit 1;
fi

read -p "Please Enter Install Directory [/opt/web] : " installDir

if [ -z $installDir ]
then
        installDir="/opt/web"
fi

echo "Cleaning old temporary Installation Files (if any)!"
rm -rf /tmp/webServer
echo "Creating Installation Directories"
mkdir $installDir
mkdir /tmp/webServer

cd /tmp/webServer

mkpass() {
  [ "$2" == "0" ] && CHAR="[:alnum:]" || CHAR="[:graph:]"
    cat /dev/urandom | tr -cd "$CHAR" | head -c ${1:-32}
    echo
}

retrieveApache() {
        $(wget http://mirror.rmg.io/apache//httpd/httpd-2.2.21.tar.gz -O /tmp/webServer/httpd.tar.gz –quiet)
        echo "Extracting Apache"
        $(tar -zxvf /tmp/webServer/httpd.tar.gz > /dev/null)
        echo "Apache Downloaded and Extracted!"
        cd /tmp/webServer
}

buildApache() {
        cd /tmp/webServer/httpd-2.2.21
        ./configure –prefix=$installDir/apache –enable-shared=max –enable-module=rewrite –enable-module=so
        make && make install
        ln -s $installDir/apache/bin/apachectl /etc/rc.d/init.d/apache
}

retrievemySQL() {
        cd /tmp/webServer
        wget http://www.mirrorservice.org/sites/ftp.mysql.com/Downloads/MySQL-5.5/mysql-5.5.20-linux2.6-$(uname -m).tar.gz -O /tmp/webServer/mySQL.tar.gz –quiet
        echo "Extracting mySQL"
        tar -zxvf /tmp/webServer/mySQL.tar.gz
        echo "mySQL Downloaded and Extracted!"
}

buildmySQL() {
        cd /tmp/webServer/mysql-5.5.20
        echo "Creating MySQL User and Group"
        groupadd mysql
        useradd -g mysql -c "MySQL Server" mysql
        echo "Starting the MySQL Build"
        ./configure –prefix=$installDir/mysql –localstatedir=$installDir/mysql/data –disable-maintainer-mode –with-musqld-user=mysql –with-unix-socket-path=/tmp/mysql.sock –without-comment –withour-debug –without-bench
        make && make install

}

configmySQL() {
        cd /tmp/webServer/mysql-5.5.20
        scripts/mysql_install_db
        chown -R root:mysql $installDir/mysql
        chown -R mysql:mysql $installDir/mysql/data
        cp support-files/my-medium.cnf /etc/my.cnf
        chown root:root /etc/my.cnf
        chmod 644 /etc/my.cnf
        echo "$installDir/mysql/lib/mysql" >> /etc/ld.so.conf
        ldconfig
        cd $installDir/mysql/bin
        for file in *; do ln -s $installDir/mysql/bin/$file /usr/bin/$file; done
        cd /tmp/webServer/mysql-5.5.20
        cp ./support-files/mysql.server /etc/rc.d/init.d/mysql
        chmod +x /etc/rc.d/init.d/mysql
        /etc/rc.d/init.d/mysql start
        mysql -u root password $sqlrootPass
        /etc/rc.d/init.d/mysql stop
        clear
        
}

retrievePHP() {
        cd /tmp/webServer
        wget http://uk.php.net/distributions/php-5.3.9.tar.gz -O /tmp/webServer/php.tar.gz –quiet
        echo "Extracting PHP"
        tar -zxvf /tmp/webServer/php.tar.gz > /dev/null
        echo "PHP Downloaded and Extracted!"
        cd /tmp/webServer
}

buildPHP() {
        cd /tmp/webServer/php-5.3.9
        ./configure –with-apxs=$installDir/apache/bin/apxs –disable-debug –enable-ftp –enable-inline-optimization –enable-magic-quotes –enable-mbstring –enable-mm=shared –enable-safe-mode –enable-track-vars –enable-trans-sid –enable-wddx=shared –enable-xml –with-dom –with-gd –with-gettext –with-mysql=$installDir/mysql –with-regex=system –with-xml –with-zlib-dir=/usr/lib
        make && make install
        cp php.ini-dist /usr/local/lib/php.ini
        ln -s /usr/local/lib/php.ini /etc/php.ini
}

read -p "Install Apache [Y/n] : " apacheInst
read -p "Install mySQL [Y/n] : " mySQLInst
read -p "Install PHP [Y/n] : " PHPInst
if [ "$mySQLInst" != "n" ]
then
        read -p "Please enter your new mySQL root password (if blank one will be generated) : " sqlrootPass
        if [ -z $sqlrootPass ]
        then
                sqlrootPass=$(mkpass 20 0)
        fi
fi

if [ "$apacheInst" != "n" ]
then
        echo "Retrieving Apache…"
        retrieveApache
        echo "Building Apache…"
        buildApache
        clear
fi

if [ "$mySQLInst" != "n" ]
then
        echo "Retrieving mySQL…"
        retrievemySQL
        echo "Building mySQL…"
        buildmySQL
        echo "mySQL Build Completed now launching configuration."
        configmySQL
        clear
fi

if [ "$PHPInst" != "n" ]
then
        echo "Retrieving PHP…"
        retrievePHP
        echo "Building PHP…"
        buildPHP
        clear
fi

rm -rf /tmp/webServer
clear
echo "It's done Ram Instalation Complete!!"
echo "Installation Directory : $installDir"
echo "mySQL Root Password    : $sqlrootPass"
echo ""
read -p "Start Services ? [Y/n]" $startServices
if [ "$startServices" != "n" ]
then
        echo "Starting Apache"
        /etc/rc.d/init.d/apache start
        echo "Starting mySQL"
        /etc/rc.d/init.d/mysql start
        
fi
echo "Hey Ram let's drink a beer " 
