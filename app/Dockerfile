FROM node:16-alpine3.14

WORKDIR /usr/src/app

COPY . .
RUN npm ci --only-production && npm run build

EXPOSE 80
CMD ["npm", "start"]
