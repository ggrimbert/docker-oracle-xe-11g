#!/bin/bash
LISTENER_ORA=/u01/app/oracle/product/11.2.0/xe/network/admin/listener.ora
TNSNAMES_ORA=/u01/app/oracle/product/11.2.0/xe/network/admin/tnsnames.ora

cp "${LISTENER_ORA}.tmpl" "$LISTENER_ORA" &&
sed -i "s/%hostname%/$HOSTNAME/g" "${LISTENER_ORA}" &&
sed -i "s/%port%/1521/g" "${LISTENER_ORA}" &&
cp "${TNSNAMES_ORA}.tmpl" "$TNSNAMES_ORA" &&
sed -i "s/%hostname%/$HOSTNAME/g" "${TNSNAMES_ORA}" &&
sed -i "s/%port%/1521/g" "${TNSNAMES_ORA}" &&

service oracle-xe start

export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_SID=XE

if [ "$ORACLE_ALLOW_REMOTE" = true ]; then
  echo "alter system disable restricted session;" | sqlplus -s SYSTEM/oracle
fi

echo "GRANT CONNECT,DBA TO SYSTEM;" | sqlplus -s "SYS/oracle" AS SYSDBA
echo "GRANT EXECUTE ON dbms_lock TO SYSTEM;" | sqlplus -s "SYS/oracle" AS SYSDBA

echo "DECLARE V_COUNT INTEGER; V_CURSOR_NAME INTEGER; V_RET INTEGER; BEGIN SELECT COUNT(1) INTO V_COUNT FROM ALL_USERS WHERE USERNAME = 'SEQUELIZE'; IF V_COUNT = 0 THEN EXECUTE IMMEDIATE 'CREATE USER sequelize IDENTIFIED BY sequelize DEFAULT TABLESPACE USERS'; EXECUTE IMMEDIATE 'GRANT CONNECT TO sequelize'; EXECUTE IMMEDIATE 'GRANT DBA TO sequelize'; EXECUTE IMMEDIATE 'ALTER USER sequelize QUOTA UNLIMITED ON USERS'; END IF; END;" | sqlplus -s "SYS/oracle" AS SYSDBA

for f in /docker-entrypoint-initdb.d/*; do
  case "$f" in
    *.sh)     echo "$0: running $f"; . "$f" ;;
    *.sql)    echo "$0: running $f"; echo "exit" | /u01/app/oracle/product/11.2.0/xe/bin/sqlplus "SYS/oracle" AS SYSDBA @"$f"; echo ;;
    *)        echo "$0: ignoring $f" ;;
  esac
  echo
done
