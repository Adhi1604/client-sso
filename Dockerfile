# Start with the base JDK image
#FROM ubuntu:20.04
FROM asia-south1-docker.pkg.dev/cnw-akku-java-development/akku-v2-dev/ubuntu-dev:akku-v2
# Set the working directory inside the container
WORKDIR /usr/src/app

# Install necessary tools (including gcloud, openjdk-17-jdk, and maven)
#RUN apt-get update && \
#    apt-get install -y curl gnupg && \
#    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
#    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
#    apt-get update && \
#    apt-get install -y google-cloud-sdk openjdk-17-jdk

# Install ping and nano
RUN apt-get update && \
    apt-get install -y iputils-ping nano

# Add custom hosts entry
#RUN echo "34.47.237.179  krb.rfx.directory" >> /etc/hosts

# Copy the service account credentials file into the container
#COPY cnw-akku-java-development.json /usr/src/app/cnw-akku-java-development.json

# Set the environment variable for Google Application Credentials
#ENV GOOGLE_APPLICATION_CREDENTIALS="/usr/src/app/cnw-akku-java-development.json"

# Activate the service account and set the project
#RUN gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS && \
    #gcloud config set project cnw-akku-java-development

# Copy the application source code into the container
COPY . .

# Make SAP native library visible to JVM
ENV LD_LIBRARY_PATH=/usr/src/app/lib

# Build the application
RUN ./mvnw clean install -DskipTests
    
# Expose the port
EXPOSE 8080

ENV MAVEN_OPTS=-Dfile.encoding=UTF-8

ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8 -Djava.library.path=/usr/src/app/lib"



# Start the application using Quarkus in development mode
CMD ["java","-Djava.library.path=/usr/src/app/lib","-jar","target/quarkus-app/quarkus-run.jar"]