# CentOS_Tomcat_OpenJDK
A container w Centos 7, OpenJDK 11.x, OpenSSL 1.x and Tomcat 9.x / Tomcat Native Library

#### Get the image from dockerhub
Get this container with:
docker pull techcasita/centos_tomcat_openjdk


#### Or build, Tag, and Push the image to dockerhub

docker build -t centos_tomcat_openjdk .
docker tag centos_tomcat_openjdk:latest techcasita/centos_tomcat_openjdk
docker login
  Username: wolfpaulus
docker push techcasita/centos_tomcat_openjdk:latest

### Run the container

docker run --rm -it --name tc -p 8080:8080 centos_tomcat_openjdk:latest
Open a web browser at http://localhost:8080/
docker exec -it tc /bin/bash