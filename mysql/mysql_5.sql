show variables like 'version';
show variables like 'basedir';
show variables like 'datadir';
show variables like 'log_error';
show variables like 'log_bin';
show variables like 'local_infile';
show variables like "old_passwords";
show variables like "safe_show_database";
show variables like "secure_auth";
show variables like "skip_grant_tables";
show variables like 'have_merge_engine';
show variables like 'skip_networking';
show variables like "have_symlink";
show variables like "have_openssl";
show variables like "ssl_key";
show variables like "ssl_cert";
show variables like "ssl_ca";
show databases like 'test';
select user from mysql.user where user = 'root';
select user from mysql.user where user = '';
select user from mysql.user where host = '%';
select user, password from mysql.user where length(password) < 41;
select user, password from mysql.user where length(password) = 0 or password is null;
