FROM tomcat:10.1.60-jre17-temurin-noble
COPY target/Hello.war /usr/local/tomcat/webapps/Hello.war
EXPOSE 8080
