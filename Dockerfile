# Use the official Nginx image as the base image
FROM nginx:alpine

# Set the working directory inside the container
WORKDIR /usr/share/nginx/html

# Copy the chat HTML files (index.html and any other assets) from the local 'chat' directory into the container
COPY ./chat /usr/share/nginx/html

# Expose port 80 to allow web traffic to access the container
EXPOSE 80

