
The AAI Debugger (AAID) is an application to debug the security filter related
information such as the remoteUser field and the AuthPrinicipal in the servlet 
security context and the http headers send to the web application.

The AAID web application is typically protected by the normal security filters; 
either LANA2 or shibboleth together with the LLOFilter. This application can be
used to test the LANA2 and shibboleth setup and debug the login flow.

Building the project:

    mvn package

Create a deployment:
    
    mvn assembly:single
