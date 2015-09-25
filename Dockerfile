#FROM debian:jessie
#FROM ubuntu:latest

#ENV HTTP_PROXY 
#ENV HTTPS_PROXY 
#ENV http_proxy
#ENV https_proxy

#RUN apt-get update && apt-get install -y \
#	<insert list of packages here>	

#RUN useradd -ms /bin/bash <USERNAME>

#USER <USERNAME>

#WORKDIR /home/<USERNAME>

#EXPOSE <PORT>

#ADD <FROM> <TO>

#CMD [<COMMAND>, ARG1, ARG...]
