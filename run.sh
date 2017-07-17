

#  yum --nogpgcheck -y install rundeck-cli \
#  rundeck-config \
#  rundeck

if [ ! -f /etc/rundeck/profile ]; then
    echo "=>installing rundeck"
    UUID=$(uuidgen)

    rpm -q rundeck || yum -y localinstall /rpms/rundeck.rpm /rpms/rundeck-config.rpm

    #yum -y install rundeck  --nogpgcheck
    mv /app/*jar /var/lib/rundeck/libext/
    cp -r /app/etc/* /etc
    sed 's,https://localhost:4443,'$SERVER_URL',g' -i /etc/rundeck/rundeck-config.groovy
    sed 's,rundeckdb,'$MYSQL_DATABASE',g' -i /etc/rundeck/rundeck-config.groovy
    sed 's,rundeckuser,'$MYSQL_USER',g' -i /etc/rundeck/rundeck-config.groovy
    sed 's,rundeckpassword,'$MYSQL_PASSWORD',g' -i /etc/rundeck/rundeck-config.groovy
    sed 's,tochange,'$PASSWORD',g' -i /etc/rundeck/realm.properties
    sed 's,5b59f9aa-f6f5-49dd-a919-ddc35d57df4b,'$UUID',g' -i /etc/rundeck/framework.properties
    PASSWORD=""
fi

if ! test -f /etc/sysconfig/rundeckd ; then
  test -d /etc/sysconfig || mkdir /etc/sysconfig
  cat <<EOF>>/etc/sysconfig/rundeckd
RDECK_CONFIG=/etc/rundeck
RDECK_CONFIG_FILE=\${RDECK_CONFIG}/rundeck-config.groovy
RDECK_JVM_SETTINGS="\${RDECK_JVM_SETTINGS} -Drundeck.ssl.config=/etc/rundeck/ssl/ssl.properties "
EOF
fi


if [ ! -f /var/lib/rundeck/.ssh/id_rsa ]; then
    echo "=>Generating rundeck ssh key"

    mkdir -p /var/lib/rundeck/.ssh
    ssh-keygen -t rsa -b 4096 -f /var/lib/rundeck/.ssh/id_rsa -N ''
fi

if [ ! -f /etc/rundeck/ssl/truststore ]; then
    echo "=>Generating ssl cert"

    keytool -keystore /etc/rundeck/ssl/keystore \
        -alias rundeck -genkey -keyalg RSA -keypass adminadmin \
        -storepass adminadmin -dname "cn=$HOST_RUNDECK, o=OME, c=FR"
    cp /etc/rundeck/ssl/keystore /etc/rundeck/ssl/truststore
fi

echo "=>launching rundeck"

chown -R rundeck:rundeck /tmp/rundeck
chown -R rundeck:rundeck /etc/rundeck
chown -R rundeck:rundeck /var/rundeck
chown -R rundeck:rundeck /var/log/rundeck
chown -R rundeck:rundeck /var/lib/rundeck

cat /var/lib/rundeck/.ssh/id_rsa.pub

# . /lib/lsb/init-functions
test -f /etc/sysconfig/rundeck && . /etc/sysconfig/rundeck
. /etc/rundeck/profile

DAEMON="${JAVA_HOME:-/usr}/bin/java"
DAEMON_ARGS="$RDECK_JVM $RDECK_JVM_OPTS -cp ${BOOTSTRAP_CP} com.dtolabs.rundeck.RunServer /var/lib/rundeck ${RDECK_HTTP_PORT}"
rundeckd="$DAEMON $DAEMON_ARGS"

cd /var/log/rundeck
su -s /bin/bash rundeck -c "$rundeckd"
