# kabasec postman tests

# Prerequisites:
See sections below for installing Postman, setting up your Postman environment, importing the Postman test collections, configuring the liberty server, and running the tests.

1. Postman version 7.5.0 installed
2. Setup Postman environment with Git Personal access tokens
3. Import Postman test collections 
4. Liberty server configured and started.  Note the base url to the kabasec application (eg http://localhost:9080/kabasec) to use in an environment variable in Postman.


# LIBERTY SERVER sample config
In the server.xml, you will see the following:


```XML
<server description="kabasec">

    <!-- Enable features -->
    <featureManager>
        <feature>microProfile-2.0</feature>
    </featureManager>

    <!-- The issuer specified here must match the issuer configured in the jwtBuilder -->
    <mpJwt id="kabmpjwt" issuer="${jwt.issuer}" keyName="default" />

    <!-- NOTE: This id cannot be changed since it's hard coded to be used in the runtime code -->
    <jwtBuilder id="kabsecbuilder" expiresInSeconds="86400" issuer="${jwt.issuer}" keyAlias="default" />

    <keyStore id="defaultKeyStore" password="keyspass"/>

    <!-- To access this server from a remote client add a host attribute to the following element, e.g. host="*" -->
    <httpEndpoint host="*" httpPort="9080" httpsPort="9443" id="defaultHttpEndpoint"/>

    <applicationMonitor updateTrigger="mbean"/>

    
    <!-- GitHub teams to security groups mappings. Each name is groupsForTeam_(team name)
         Each value is a comma separated list of groups for this team.

         Use these groups in the jaxrs @RolesAllowed annotation.
         Team names can also be used explicitly. 
         _ can be substituted for nonalphabetic characters. 
         There's also a default group "allusers" that everyone is a member of.
    -->
    <!--
    <variable name="groupsForTeam_all-ibmers@IBM" value="operator,admin,tester,deployer,janitor" />
    <variable name="groupsForTeam_Security_SSO_OpenLiberty" value="operator,admin,jogger" />
    -->

    <!-- Encryption key for github credentials. -->
    <!-- To keep this secure, import this from another file, or  bring it in as an environment var from a kubernetes secret -->
    <!-- https://www.ibm.com/support/knowledgecenter/SSRTLW_8.5.5/com.ibm.websphere.wlp.nd.multiplatform.doc/ae/cwlp_pwd_encrypt.html -->
    <!-- <variable name="AESEncryptionKey" value="put_me_someplace_very_secure"/> -->

    <!-- this will be the issuer of the jwts -->
    <variable name="jwt.issuer" defaultValue="https://kabasec.com" />

    <!-- this will be the default base url for github api calls -->
    <variable defaultValue="https://api.github.com" name="github.api.url" />

  
    <logging  traceSpecification="*=info:com.ibm.ws.security.*=all:com.ibm.ws.webcontainer.security.*=all"
        traceFileName="trace.log" maxFileSize="20" maxFiles="10" />
</server>
```

# POSTMAN INSTALL
Below are instructions for creating the Postman environment, importing the Kabanero Login/Logout tests into Postman and executing the tests.

1. Download Postman (free version) from https://www.getpostman.com/tools
And Install postman following directions from the postman web site.

Note: the version of Postman used to create and run these tests is Postman 7.5.0.

# SET UP POSTMAN ENVIRONMENT WITH GIT PERSONAL ACCESS TOKENS
1. Import KabaneroEnvironmentSample into your Postman Installation (In postman, click on star shaped icon in upper right and select Manage Environments) and Import. Import KabaneroEnvironmentSample.  

The instructions below talk about creating a Personal Access Token. To do so, take the following steps:
 Login in to github.com
Select Settings from the drop down in upper right
Select "Developer Settings" from list at the left
Select "Personal Access Tokens" from list at the left
Select "Generate new token" button
  - Enter name for token
  - Select scopes (permissions) from list provided

Users Required in github.com:
1. You must have one user which is a member of the IBM/all-ibmers  (organization/team). This user must have 2-Factor authentication configured in github.
2. You must create another github.com user which does not have 2-Factor Authentication configured. This user must belong to a team and organization. For exmaple -- an organization (eg. yourOrg) and team (eg yourTeam). This the org and team for this user will be needed in the Manual test steps to set environment variables below.

Create personal access tokens as follows and save the values for entering into Postman environment variables.

1. Access token with repo and user scopes - good access token
2. Access token with Repo scope only
3. Access token with User scope only
4. Access token with no scopes
5. Access token with read:org scope under admin
6. Access token with user and repo scopes - create and then delete it



Update the following variables in the KabaneroEnvironmentSample to match your gitHub user and Personal Access token

- url - set the base url environment variable to point to the kabasec base url  for your server — eg. http://localhost:9090/kabasec


- gitLoginNon2FA - enter the login id for a user which does not have 2-Factor authentication configured
- gitLoginPwdNon2FA - enter the password for your non-2FA git user
- gitLogin2FA - the login id for your github.com with 2-Factor authentication configured
- gitLogin2FAPlainPwd - the password for the 2FA user (where PAT is required) rather than plain pwd
- noRoleToken - a personal access token with no roles selected on creation
- patRepoScope - a personal access token with only Repo role selected
- patUserScope - a personal access token with only User role selected
- patReadOrgScope - a personal access token with only read:org under Admin
- noRoleToken - token which has no scopes
- goodAccessToken - token which has user and repo scopes.
- patRevoked - access token with user and repo scopes that has been deleted.
- patWriteDiscussionPackages - access token with Write scopes for Discussion, Write and Read Packages


Make this environment your active postman environment.

# IMPORT POSTMAN TEST COLLECTIONS

1. From the Postman task bar, select File…Import and import the following test collections:
- KabaneroLoginLogout 
- KabaneroJWTAndSSLErrors
- KabaneroJWTExpiration
- KabaneroLoginLogoutE2E

Once imported, go to Collections view in Postman and verify that you have a collection by each of those names.


# RUN POSTMAN TESTS
## Manual test
1. Start Liberty server and verify the server is started
2. Go to the KabaneroLoginLogout collection and attempt to run the first test -- KabPATLogin_Success. Press Send.
Since there were no users or groups configured, you should see the return code 400 Bad Request 
with the message: "An error occurred. An error occurred during authentication for user [gitUser]. Error while building a JWT for user [gitUser]. kabasec.KabaneroSecurityException: The user is not a member of any known teams."

3. Stop the Liberty server and export the following environment variables.
export AESEncryptionKey=mytopsecretkey
export teamsInGroup_admin="all-ibmers@IBM"
export teamsInGroup_operator="yourTeam@yourOrg"

4. Start the Liberty server after settingt he environment variables.
5. Continue with running the tests below. 

## KabaneroLoginLogout
1. To run an individual test, highlight that test and select Send. Verify that the Test Results show success. 
Initially, select the test “KabPATLogin_Success” and press Send to run that test. You should see that 3/3 tests are successful if your environment is set up correctly.

2. To run the entire collection, click on the right arrow next to the collection and select Run. The collection and select “Run KabaneroLoginLogout” button.  You should see run results showing number of Passed and Failed tests.

## KabaneroLoginLogoutE2E
1. Click on the collection and select Run.


## KabaneroJWTAndSSLErrors (with manual setup prior to each test)
Note: This collection requires manual setup and run steps.
### KabLogin_BadJWTKeyAlias_Error500

1. Prior to test KabLogin_BadJWTKeyAlias_Error500, go to your target Liberty server.xml and make the following change:
Update server.xml to change the jwtBuilder config from:
    <jwtBuilder id="kabsecbuilder" expiresInSeconds="86400" issuer="${jwt.issuer}" keyAlias="default" />
to use a nonExisting key alias
    <jwtBuilder id="kabsecbuilder" expiresInSeconds="86400" issuer="${jwt.issuer}" keyAlias="nonexisting" />

2. Make sure your server is restarted with the new configuration.

3. Run KabLogin_BadJWTKeyAlias_Error500 and verify the test is successful.

### KabLogin_BadSSLKeyPassword_Error500
1. Prior to this test, got to your target Liberty server.xml and make the following change.
Change the password for the default keystore:
	<keyStore id="defaultKeyStore" password="keyspass"/>
to using a nonexisting password
	<keyStore id="defaultKeyStore" password="nonexistingkeyspass"/>
2. Make sure your server is restarted with the new configuration.
3. Run KabLogin_BadSSLKeyPassword_Error500 and verify that the test is successful.

## KabaneroJWTExpiration (manual config update prior to running collection)
Note: This test requires a manual config update to server.xml prior to running the collection.

1. Update server.xml to change the expiration time for the jwt 

    <jwtBuilder id="kabsecbuilder" expiresInSeconds="86400" issuer="${jwt.issuer}" keyAlias="default" />
to    
 <jwtBuilder id="kabsecbuilder" expiresInSeconds="5" issuer="${jwt.issuer}" keyAlias="default" />

2. Make sure your server is restarted with the configuration change.
3. Right click on the KabaneroJWTExpiration and select run to run the collection.  There will be a delay during the test execution, so you will need to wait for several minutes to see the test results.

