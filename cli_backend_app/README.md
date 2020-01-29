# Welcome to the Kabanero CLI backend app and related files.

# THE APP CODE IS MOVED TO https://github.com/kabanero-io/kabanero-command-line-services


Having a recent Liberty build is recommended.  19.0.0.3 is the minimum, (or maybe higher).

# Table of Contents
1. [Developing and building the app](#developing-and-building-the-app)
    1. [Importing the project into Eclipse](#Importing-the-project-into-Eclipse)
    1. [Building the app](#Building-the-app)
        1. [Build using Maven](#Build-using-Maven)
            1. [Build from the command line](#Build-from-the-command-line)
            1. [Build from Eclipse](#Build-from-Eclipse)
        1. [Exporting the WAR from Eclipse](#Exporting-the-WAR-from-Eclipse)
        1. [Build with WDT](#Build-with-WDT)
    1. [Running the app](#Running-the-app)
1. [Using and testing the app](#Using-and-testing-the-app)
    1. [Setup and use ](#Setup-and-Use)
        1. [Obtaining the authenticated user's personal access token to perform additional GitHub operations](#Obtaining-the-authenticated-users-personal-access-token-to-perform-additional-GitHub-operations)
    1. [Error messages](#Error-messages)
    1. [Sample Dockerfile](#Sample-Dockerfile)

# Developing and building the app

## Importing the project into Eclipse

Import the app folder into eclipse as an existing eclipse project.  If you have a WDT workspace you can run it on Liberty directly from Eclipse.  You'll probably have to touch up the classpath to locations on your system.

## Building the app

There are a few ways of going about building the application and producing the WAR file that's used by the server:
1. [Build using Maven](#build-using-maven)
1. [Exporting the WAR from Eclipse](#exporting-the-war-from-eclipse)
1. [Build with WDT](#build-with-wdt)

### Build using Maven

As of commit [`9776648`](https://github.ibm.com/btiffany/kabasec/commit/977664862248e0067fabaa42f6344a95eebc0325), the project can be built with Maven. There are two ways to do this: from the command line or from Eclipse.

#### Build from the command line

Navigate to the `app` directory and issue the following command:

```
$ mvn clean install
```

That will generate a `target/` directory in which the `kabasec.war` file will be generated.

#### Build from Eclipse

Most versions Eclipse likely have Mavin plugins natively included which you can use to build the project.

1. Right-click on the project in Package Explorer or Project Explorer.
1. Select Run As > Maven build
1. A dialog box will likely pop up with a bunch of input fields. One of those fields will be something like "Goals" or "Goals to run". In that field, put `clean install`.
1. Click the Run button at the bottom of the dialog box.

The output of the run will go to the Console view in Eclipse and will generate a `target/` directory and `kabasec.war` file just as if you had run the build from the command line.

### Exporting the WAR from Eclipse

Once all the red is out of the project, right click on the project in Project or Package Explorer and select "export as WAR file" to export the WAR. You can choose the directory to which you'd like to export the WAR.

### Build with WDT

I (Adam) actually never got this working, so I have no idea how to set this up.

## Running the app

- Copy the `server/` directory contained in this repo into the `dev/build.image/wlp/usr/servers/` directory of an Open Liberty installation. You can rename the folder to anything you'd like if you won't want your server to be called "server". The `server/` directory already contains everything that's needed to run the server and app, aside from the app itself.
- Create a `dropins/` directory within the server root and copy the `kabasec.war` file generated from [Building the app](#building-the-app) into it.

If targeting Docker, see the sample Dockerfile below.

# Using and testing the app

## Setup and Use

1. Recommeded Setup:

    * Set the encryption key used to protect GitHub credentials. Set an environment variable
       named `AESEncryptionKey` to the value of the key.  The value can be any string. 
       If the key is not set, a random key will be generated that will not survive a server restart
       and will not be the same between two containers. 
        * Example: AESEncryptionKey=top_secret_string_goes_here.
        * Github passwords or personal access tokens submitted to the login endpoint
          will be AES encrypted and stored in the returned JWT.      
        * The JWT itself is signed, but not encrypted. 

    * Map GitHub teams to security groups. 
        * Set up GitHub teams for your organization as described [here](https://help.github.com/en/articles/organizing-members-into-teams)
        * Next define environment variables that specify what security groups each team is in.
        * A user must be a member of at least one defined team, or login will fail. 
        * Define environment variables in this format: 
             * A name of teamsInGroup_(group name) 
             * A value of a comma separated list of teams.
        * Be sure to use the fully qualified name, i.e. "team name and-id@org"    
        * Example:  For the team all-ibmers@IBM to be in the admin and operator groups, and the team "test team@XYZ" to be in the operator group, specify two environment variables:
            * teamsInGroup_admin="all-ibmers@IBM"
            * teamsInGroup_operators="all-ibmers@IBM,test team@XYZ"

    * Old, deprecated way to map GitHub teams to security groups, not recommended:
        * You'll define environment variables with a name of groupsForTeam_(team name) 
           and a value being a comma separated list of groups.
        * Be sure to use the fully qualified name, i.e. team_name@org.
        * If your team name contains any nonalphanumeric characters, replace them with an underscore (_).
        * Example:  For the team all-ibmers@IBM to be in the admin and operator groups, specify  groupsForTeam_all_ibmers_IBM=operator,admin

1. Optional Setup: 

    * Set the URL to the GitHub API's.  If using a private GitHub server, set the environment variable `github_api_url`. For example,
       `github_api_url=https://api.github.mycompany.com`


1. Login

    You can use a personal access token (preferred) or your Github password. Use of passwords is only supported
    for Github accounts that are not configured to require two factor authentication.

    Send an HTTP POST request to the `/login` endpoint, similar to shown here.  
    ```
    curl -k -v \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"gituser":"<YOUR-GITHUB-ID>","gitpat":"<YOUR-GITHUB-PERSONAL-ACCESS-TOKEN-OR-PASSWORD"}' \
    http://localhost:9080/kabasec/login
    ```

    The body of the request must be a JSON object with two keys: `"gituser"` and `"gitpat"`. The value for `"gituser"` is your GitHub user ID and the value for `"gitpat"` is a personal access token generated through GitHub (see [Creating a personal access token for the command line](https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line)).

    A successful response from this endpoint should look similar to what's shown here:

    ```JSON
    {
        "jwt": "eyJraWQiOiJVSXBsRWo5QVhkdlduNm54UTI3eVA0cjdsYVVvbjVTRlBNMTRrcTlYbGhVIiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYifQ.eyJ0b2tlbl90eXBlIjoiQmVhcmVyIiwic3ViIjoiYXlvaG9AdXMuaWJtLmNvbSIsInVwbiI6ImF5b2hvQHVzLmlibS5jb20iLCJncm91cHMiOlsiYWxsLWlibWVyc0BJQk0iXSwiaXNzIjoiaHR0cHM6Ly9rYWJhc2VjLmNvbSIsImV4cCI6MTU2NTM3NjIyNiwiaWF0IjoxNTY1Mjg5ODI2fQ.blh1pMhSVX0CtS_GaZxmb-CePNXzsQCsGTxlAVLBCqDYJLuoeQvRScPqDokoGPzrg91b5jwJuG1AK4QYw7BifTafadNj5AY6Gg3KV-aDWjwFx8ql_wmPL37gDCHrgCHDLYHgcQ4AB928E8ycTBKsNAhucZmGiGwBYHBXLDZu9Szn8dZ0RrH7e-JK5fuoyS9cgYerWyTlH9kihqvECGcu1ykBPlqBaYYLBl7sVmBq5k3ZbkytvLQQ4Ol61d5mOyGYaoUz2BJS26U_HcAsxbXO-GASIXWQgdOm8c53Oi_IB6PQuIGlwfX-_4BLvLiuIoC8ocwEGFcZs3lRz6bn_kUq5Q",
        "message": "ok"
    }
    ```

1. Secured Ping

   Take the JWT that was returned from the `/login` endpoint and send an HTTP POST request to the `/securedping` endpoint.

    ```
    curl -k -v -X POST \
    -H "Authorization: Bearer <JWT-STRING>" \
    -H "Accept: application/json" \
    http://localhost:9080/kabasec/securedping
    ```

    A successful response from this endpoint should look similar to the following:

    ```JSON
    {
        "success": "true",
        "message": "pong"
    }
    ```

1. Admin Ping - works just like ping except the user has to be in the admin group. URL is http://localhost:9080/kabasec/adminping

1. Logout

    Take the JWT that was returned from the `/login` endpoint and send an HTTP POST request to the `/logout` endpoint.

    ```
    curl -k -v -X POST \
    -H "Authorization: Bearer <JWT-STRING>" \
    -H "Accept: application/json" \
    http://localhost:9080/kabasec/logout
    ```

    A successful response from this endpoint should look similar to the following:

    ```JSON
    {
        "success": "true",
        "message": "ok"
    }
    ```

### Obtaining the authenticated user's personal access token to perform additional GitHub operations

Within a secured resource:

```Java
String pat = new kabasec.PATHelper().extractGithubAccessTokenFromSubject();
```

## Error messages

As much as possible, error detail is returned in the response JSON.

On the first request only, this will appear in the log:
```
[ERROR   ] CWMOT0008E: OpenTracing cannot track JAX-RS requests because an OpentracingTracerFactory class was not provided.
```
and can be ignored.  Configuring OpenTracing, if desired, will remove this error.   Logging can also be configured to suppress it.

## Sample Dockerfile

```
FROM open-liberty:webProfile7-java8-openj9
RUN mkdir -p /opt/ol/wlp/output/defaultServer/resources/security
RUN chown -R 1001:0 /opt/ol/wlp/output/defaultServer/resources/security
RUN chmod -R g+rw /opt/ol/wlp/output/defaultServer/resources/security    
COPY cacerts /opt/ol/wlp/output/defaultServer/resources/security
COPY server.xml /opt/ol/wlp/usr/servers/defaultServer/server.xml
COPY kabasec.war /opt/ol/wlp/usr/servers/defaultServer/apps/kabasec.war
```
