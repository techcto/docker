echo "Install restore scripts"
yum install -y duplicity duply python-boto mysql --enablerepo=epel
curl -qL -o jq https://stedolan.github.io/jq/download/linux64/jq && chmod +x ./jq

#Backup Script
echo "Create mysql backup script"
echo '#!/bin/bash' > /root/dumpmysql.sh
echo "mkdir -p /var/www/Solodev/clients/solodev/dbdumps" >> /root/dumpmysql.sh
echo "PWD=/var/www/Solodev/clients/solodev/dbdumps" >> /root/dumpmysql.sh
echo 'DBFILE=$PWD/databases.txt' >> /root/dumpmysql.sh
echo 'rm -f $DBFILE' >> /root/dumpmysql.sh
echo "/usr/bin/mysql -u root -p$PASSWORD mysql -Ns -e \"show databases\" > \$DBFILE" >> /root/dumpmysql.sh
echo "for i in \`cat \$DBFILE\` ; do mysqldump --opt --single-transaction -u root -p$PASSWORD \$i > \$PWD/\$i.sql ; done" >> /root/dumpmysql.sh
echo "# Compress Backups" >> /root/dumpmysql.sh
echo 'for i in `cat $DBFILE` ; do gzip -f $PWD/$i.sql ; done' >> /root/dumpmysql.sh
chmod 700 /root/dumpmysql.sh

#Duply Config
echo "Init Duply backup config"
duply backup create
perl -pi -e 's/GPG_KEY/#GPG_KEY/g' /etc/duply/backup/conf
perl -pi -e 's/GPG_PW/#GPG_PW/g' /etc/duply/backup/conf
echo "GPG_PW=$PASSWORD" >> /etc/duply/backup/conf
echo "TARGET='s3+http://BACKUP-BUCKET/backups'" >> /etc/duply/backup/conf
echo "export AWS_ACCESS_KEY_ID='IAM_ACCESS_KEY'" >> /etc/duply/backup/conf
echo "export AWS_SECRET_ACCESS_KEY='IAM_SECRET_KEY'" >> /etc/duply/backup/conf
echo "SOURCE=$MOUNT" >> /etc/duply/backup/conf
echo "MAX_AGE='1W'" >> /etc/duply/backup/conf
echo "MAX_FULL_BACKUPS='2'" >> /etc/duply/backup/conf
echo "MAX_FULLBKP_AGE=1W" >> /etc/duply/backup/conf
echo "VOLSIZE=100" >> /etc/duply/backup/conf
echo 'DUPL_PARAMS="$DUPL_PARAMS --volsize $VOLSIZE"' >> /etc/duply/backup/conf
echo 'DUPL_PARAMS="$DUPL_PARAMS --full-if-older-than $MAX_FULLBKP_AGE"' >> /etc/duply/backup/conf
echo "/root/dumpmysql.sh >/dev/null 2>&1" > /etc/duply/backup/pre
echo "mongodump --out $MOUNT/mongodumps > /dev/null 2>&1" >> /etc/duply/backup/pre

#Backup Script
echo "/root/dumpmysql.sh" > /root/backup.sh
echo "duply backup backup" >> /root/backup.sh
chmod 700 /root/backup.sh

#Restore Script
echo "Generate restore script"
echo "#!/bin/bash" > /root/restore.sh
echo "mv $MOUNT/Client_Settings.xml $MOUNT/Client_Settings.xml.bak" >> /root/restore.sh
echo "export PASSPHRASE=$PASSWORD" >> /root/restore.sh
echo "export AWS_ACCESS_KEY_ID='IAM_ACCESS_KEY'" >> /root/restore.sh
echo "export AWS_SECRET_ACCESS_KEY='IAM_SECRET_KEY'" >> /root/restore.sh
echo "duplicity --force -v8 restore s3+http://RESTORE-BUCKET/backups $MOUNT" >> /root/restore.sh
echo "chmod -Rf 2770 $MOUNT" >> /root/restore.sh
echo "chown -Rf apache.apache $MOUNT" >> /root/restore.sh
echo "gunzip < $MOUNT/dbdumps/solodev.sql.gz | mysql -u root -p$PASSWORD solodev" >> /root/restore.sh
echo "mongorestore $MOUNT/mongodumps" >> /root/restore.sh
echo "rm -f $MOUNT/Client_Settings.xml" >> /root/restore.sh
echo "mv $MOUNT/Client_Settings.xml.bak $MOUNT/Client_Settings.xml" >> /root/restore.sh
chmod 700 /root/restore.sh