# Use the official Nginx image from Docker Hub
FROM nginx:latest

# The Nginx image already serves files from /usr/share/nginx/html
# and includes a default configuration.
# Our custom config and html files will be mounted at runtime from the EC2 host.
# Therefore, we don't need to copy any files here.
# This keeps the image generic and lightweight.