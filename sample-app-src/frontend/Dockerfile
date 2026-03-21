FROM node:18-alpine

WORKDIR /app

# Copy app.js from the build context (frontend folder)
COPY app.js /app/app.js

EXPOSE 8080
CMD ["node", "app.js"]
