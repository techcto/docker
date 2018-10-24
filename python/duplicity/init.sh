#Mysql Dump Script
if [ ! -f '/root/.duply/dumpmysql.sh' ] ; then
    echo "Create mysql backup script"
    echo '#!/bin/sh' > /root/.duply/dumpmysql.sh
    echo "mkdir -p $MOUNT/dbdumps" >> /root/.duply/dumpmysql.sh
    echo "PWD=$MOUNT/dbdumps" >> /root/.duply/dumpmysql.sh
    echo 'DBFILE=$PWD/databases.txt' >> /root/.duply/dumpmysql.sh
    echo 'rm -f $DBFILE' >> /root/.duply/dumpmysql.sh
    echo "mysql -h $DB_HOST -u root -p$DB_PASSWORD mysql -Ns -e \"SELECT GROUP_CONCAT(SCHEMA_NAME SEPARATOR ' ') FROM information_schema.SCHEMATA WHERE SCHEMA_NAME NOT IN ('mysql','information_schema','performance_schema','sys');\" > \$DBFILE" >> /root/.duply/dumpmysql.sh
    echo "for i in \`cat \$DBFILE\` ; do mysqldump --opt --single-transaction -h $DB_HOST -u root -p$DB_PASSWORD \$i > \$PWD/\$i.sql ; done" >> /root/.duply/dumpmysql.sh
    echo "# Compress Backups" >> /root/.duply/dumpmysql.sh
    echo 'for i in `cat $DBFILE` ; do gzip -f $PWD/$i.sql ; done' >> /root/.duply/dumpmysql.sh
    chmod 700 /root/.duply/dumpmysql.sh
fi

#Duply Config
if [ ! -f '/root/.duply/backup/conf' ] ; then
    echo "Init Duply backup config"
    #TODO: Replace Duply with pure duplicity commands
    duply backup create
    perl -pi -e 's/GPG_KEY/#GPG_KEY/g' /root/.duply/backup/conf
    perl -pi -e 's/GPG_PW/#GPG_PW/g' /root/.duply/backup/conf
    echo "GPG_PW=$GPG_PW" >> /root/.duply/backup/conf
    echo "TARGET=s3+http://$BUCKET" >> /root/.duply/backup/conf
    echo "export AWS_ACCESS_KEY_ID=$IAM_ACCESS_KEY" >> /root/.duply/backup/conf
    echo "export AWS_SECRET_ACCESS_KEY=$IAM_SECRET_KEY" >> /root/.duply/backup/conf
    echo "SOURCE=$MOUNT" >> /root/.duply/backup/conf
    echo "MAX_AGE='1W'" >> /root/.duply/backup/conf
    echo "MAX_FULL_BACKUPS='2'" >> /root/.duply/backup/conf
    echo "MAX_FULLBKP_AGE=1W" >> /root/.duply/backup/conf
    echo "VOLSIZE=100" >> /root/.duply/backup/conf
    echo 'DUPL_PARAMS="$DUPL_PARAMS --volsize $VOLSIZE --allow-source-mismatch"' >> /root/.duply/backup/conf
    echo 'DUPL_PARAMS="$DUPL_PARAMS --full-if-older-than $MAX_FULLBKP_AGE"' >> /root/.duply/backup/conf
    echo "/root/.duply/dumpmysql.sh" > /root/.duply/backup/pre
    echo "mongodump -u $DB_USER -p $DB_PASSWORD -d $MONGO_DB --host $MONGO_HOST --out $MOUNT/mongodumps" >> /root/.duply/backup/pre
    #Backup Script
    echo "/root/.duply/dumpmysql.sh" > /root/.duply/backup.sh
    echo "duply backup backup" >> /root/.duply/backup.sh
    chmod 700 /root/.duply/backup.sh
fi

#Restore Script
if [ ! -f '/root/.duply/restore.sh' ] ; then
    #This runs after restore
    echo "gunzip < $MOUNT/dbdumps/solodev.sql.gz | mysql -u root -p$DB_PASSWORD -h $DB_HOST $DB_NAME" > /root/.duply/restore.sh
    echo "mongorestore -u $DB_USER -p $DB_PASSWORD --host $MONGO_HOST $MOUNT/mongodumps" >> /root/.duply/restore.sh
    echo "rm -f $MOUNT/Client_Settings.xml" >> /root/.duply/restore.sh
    echo "mv $MOUNT/Client_Settings.xml.bak $MOUNT/Client_Settings.xml" >> /root/.duply/restore.sh
    chmod 700 /root/.duply/*.sh
fi