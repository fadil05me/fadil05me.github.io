# Use the official Nginx image from Docker Hub
FROM nginx:alpine

# Copy the custom Nginx configuration file into the container
COPY nginx.conf /etc/nginx/nginx.conf

# Copy to html folder
COPY . /usr/share/nginx/html
