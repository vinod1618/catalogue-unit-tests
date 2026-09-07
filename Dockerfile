# FROM node:20
# #this creats and move to that directory
# WORKDIR /app
# COPY package.json .
# COPY *.js .
# RUN npm install
# ENV MONGO=true \
#     MONGO_URL="mongodb://mongodb:27017/catalogue"
# CMD ["node","server.js"]


FROM node:alpine AS builder
#this creats and move to that directory
WORKDIR /app
COPY package.json .
COPY *.js .
RUN apk update && apk upgrade
RUN npm install


FROM node:alpine
WORKDIR /app
EXPOSE 8080
COPY --from=builder /app /app
ENV MONGO=true \
    MONGO_URL="mongodb://mongodb:27017/catalogue"
RUN addgroup -S roboshop && adduser -S roboshop -G roboshop
RUN chown -R roboshop:roboshop /app
USER roboshop
ENTRYPOINT ["node"]
CMD ["server.js"]