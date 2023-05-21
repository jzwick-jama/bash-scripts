IF SERVERPROPERTY('ProductVersion') LIKE '15%' -- Check if SQL Server version is 2019 or higher
BEGIN
  -- Create databases
  CREATE DATABASE jama;
  CREATE DATABASE saml;
  CREATE DATABASE oauth;

  -- Create logins
  CREATE LOGIN jamauser WITH PASSWORD = 'password';
  CREATE LOGIN oauthuser WITH PASSWORD = 'password';
  CREATE LOGIN samluser WITH PASSWORD = 'password';

  -- Create users in respective databases
  USE jama;
  CREATE USER jamauser FOR LOGIN jamauser;
  USE saml;
  CREATE USER samluser FOR LOGIN samluser;
  USE oauth;
  CREATE USER oauthuser FOR LOGIN oauthuser;

  -- Grant privileges
  USE jama;
  ALTER ROLE db_owner ADD MEMBER jamauser;
  USE saml;
  ALTER ROLE db_owner ADD MEMBER samluser;
  USE oauth;
  ALTER ROLE db_owner ADD MEMBER oauthuser;
END
ELSE
BEGIN
  PRINT 'SQL Server version must be 2019 or higher.';
END
