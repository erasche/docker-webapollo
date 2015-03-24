#!/bin/bash

export PGUSER=postgres
export PGPASSWORD=password

export WEBAPOLLO_DATABASE=web_apollo_users
export JBROWSE_DATA_DIR=/opt/apollo/jbrowse/data
export WEBAPOLLO_DATA_DIR=/opt/apollo/annotations
export WEBAPOLLO_ROOT=/webapollo/
export JBROWSE_DIR=$WEBAPOLLO_ROOT/jbrowse-download/

echo "Sleeping on Postgres at $DB_PORT_5432_TCP_ADDR:$DB_PORT_5432_TCP_PORT"
until nc -z $DB_PORT_5432_TCP_ADDR $DB_PORT_5432_TCP_PORT; do
    echo "$(date) - waiting for postgres..."
    sleep 2
done

# Use default postgres user...
#psql -U postgres -h $DB_PORT_5432_TCP_ADDR -c "CREATE USER $PGUSER NOCREATEROLE CREATEDB NOINHERIT LOGIN NOSUPERUSER ENCRYPTED PASSWORD '$WEBAPOLLO_PASSWORD'"
psql -U postgres -h $DB_PORT_5432_TCP_ADDR -c "CREATE DATABASE $WEBAPOLLO_DATABASE ENCODING='UTF-8' OWNER=$PGUSER"

CONFIG_FILE=$DEPLOY_DIR/config/config.properties
sed -i "s|database.url=.*|database.url=jdbc:postgresql://$DB_PORT_5432_TCP_ADDR:$DB_PORT_5432_TCP_PORT/$WEBAPOLLO_DATABASE|g" $CONFIG_FILE
sed -i "s|database.username=.*|database.username=$PGUSER|g" $CONFIG_FILE
sed -i "s|database.password=.*|database.password=$PGPASSWORD|g" $CONFIG_FILE
sed -i "s|organism=.*|organism=$APOLLO_ORGANISM|g" $CONFIG_FILE

HIBERNATE_CONFIG_FILE=$DEPLOY_DIR/config/hibernate.xml
sed -i "s|ENTER_DATABASE_CONNECTION_URL|jdbc:postgresql://$DB_PORT_5432_TCP_ADDR:$DB_PORT_5432_TCP_PORT/$WEBAPOLLO_DATABASE|g" $HIBERNATE_CONFIG_FILE
sed -i "s|ENTER_USERNAME|$PGUSER|g" $HIBERNATE_CONFIG_FILE
sed -i "s|ENTER_PASSWORD|$PGPASSWORD|g" $HIBERNATE_CONFIG_FILE

XML_CONFIG_FILE=$DEPLOY_DIR/config/config.xml
sed -i "s|<authentication_class>.*</authentication_class>|<authentication_class>$APOLLO_AUTHENTICATION</authentication_class>|g" $XML_CONFIG_FILE

# TODO wait for endpoint to be alive

psql -U $PGUSER $WEBAPOLLO_DATABASE -h $DB_PORT_5432_TCP_ADDR < $WEBAPOLLO_ROOT/tools/user/user_database_postgresql.sql

mkdir -p /opt/apollo/annotations /opt/apollo/jbrowse/data/
# Need JBlib.pm
export PERL5LIB=/webapollo/jbrowse-download/src/perl5
$WEBAPOLLO_ROOT/tools/user/add_user.pl -D $WEBAPOLLO_DATABASE -U $PGUSER -P $PGPASSWORD -u $APOLLO_USERNAME -p $APOLLO_PASSWORD -H $DB_PORT_5432_TCP_ADDR

/bin/autodetect.sh /data

# Run tomcat and tail logs
cd $CATALINA_HOME && ./bin/catalina.sh run
