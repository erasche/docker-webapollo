#!/bin/bash
/etc/init.d/postgresql start
sudo -u postgres createuser --no-superuser --createdb --no-createrole web_apollo_users_admin
sudo -u postgres psql -c "ALTER USER web_apollo_users_admin WITH ENCRYPTED PASSWORD 'password'"
sudo -u postgres createdb -O web_apollo_users_admin web_apollo_users
# Add a user and do DB setup
cd $WEB_APOLLO_DIR/tools/user
psql -U web_apollo_users_admin web_apollo_users < user_database_postgresql.sql
./add_user.pl -D web_apollo_users -U web_apollo_users_admin -P password -u web_apollo_admin -p web_apollo_admin
# Ready to go!
./extract_seqids_from_fasta.pl -p Annotations- -i $WEB_APOLLO_SAMPLE_DIR/scf1117875582023.fa -o /tmp/seqids.txt
./add_tracks.pl -D web_apollo_users -U web_apollo_users_admin -P password -t /tmp/seqids.txt
./set_track_permissions.pl -D web_apollo_users -U web_apollo_users_admin  -P password -u web_apollo_admin -t /tmp/seqids.txt -a

cd /usr/local/tomcat/webapps/WebApollo/jbrowse/ \
    && bin/add-webapollo-plugin.pl -i data/trackList.json \
    && bin/generate-names.pl \
    && bin/add-bam-track.pl --bam_url bam/simulated-sorted.bam \
    --label simulated_bam --key "simulated BAM" \
    && bin/add-bw-track.pl --bw_url bigwig/simulated-sorted.coverage.bw \
    --label simulated_bw --key "simulated BigWig" \

$CATALINA_HOME/bin/catalina.sh run
