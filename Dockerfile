# Use the official Nginx image from Docker Hub
FROM nginx:latest

# Remove the default nginx index page
RUN rm /usr/share/nginx/html/index.html

# Copy our custom html and configuration files
COPY ./html/ /usr/share/nginx/html/
COPY ./default.conf /etc/nginx/conf.d/default.conf
