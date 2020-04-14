FROM node:10
WORKDIR /usr/src/app
RUN apt install git -y
RUN git clone https://github.com/gothinkster/react-redux-realworld-example-app.git /usr/src/app
RUN npm install
CMD [ "npm", "start" ]
EXPOSE 4100
