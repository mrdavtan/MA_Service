# Use the official Nginx image as the base image
FROM nginx:alpine

# Set the working directory inside the container
WORKDIR /usr/share/nginx/html

# Copy the chat HTML files from the local 'chat' directory
COPY ./chat /usr/share/nginx/html/

# Create nginx config directory if it doesn't exist
RUN mkdir -p /etc/nginx/conf.d

# Copy custom nginx configuration
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Expose port 80
EXPOSE 80
