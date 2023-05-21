CONFIGMYSQL //

-- Check if MySQL version is 8 or higher
CREATE PROCEDURE verify_version_and_setup()
BEGIN
  SELECT VERSION() INTO @mysql_version;
  IF SUBSTRING_INDEX(@mysql_version, '.', 1) >= 8 THEN
    -- Create databases
    CREATE DATABASE IF NOT EXISTS jama CHARACTER SET utf8mb4;
    CREATE DATABASE IF NOT EXISTS saml;
    CREATE DATABASE IF NOT EXISTS oauth;

    -- Create users
    CREATE USER IF NOT EXISTS 'jamauser'@'%' IDENTIFIED BY 'password';
    CREATE USER IF NOT EXISTS 'oauthuser'@'%' IDENTIFIED BY 'password';
    CREATE USER IF NOT EXISTS 'samluser'@'%' IDENTIFIED BY 'password';

    -- Grant privileges
    GRANT ALL PRIVILEGES ON jama.* TO 'jamauser'@'%';
    GRANT ALL PRIVILEGES ON oauth.* TO 'oauthuser'@'%';
    GRANT ALL PRIVILEGES ON saml.* TO 'samluser'@'%';
  ELSE
    SELECT 'MySQL version must be 8 or higher.';
  END IF;
END //

CONFIGMYSQL ;