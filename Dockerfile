# Description: Dockerfile for the database container

# Use the official Postgres image
FROM postgres:15

# Set the environment variables
ENV POSTGRES_USER=app_user
ENV POSTGRES_PASSWORD=app_password
ENV POSTGRES_DB=microservices

# Copy the init.sql file to the docker-entrypoint-initdb.d directory
COPY ./init.sql /docker-entrypoint-initdb.d/

# Expose the Postgres port
EXPOSE 5432