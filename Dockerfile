FROM node:12.16-alpine as install-npm

RUN mkdir -p /app
WORKDIR /app

# install deps
COPY package*.json /app/
RUN npm install

FROM node:12.16-alpine

RUN mkdir -p /app
WORKDIR /app

ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Copy deps
COPY --from=install-npm /app/node_modules /app/node_modules

# Setup workdir
COPY . /app

# run
EXPOSE 9000
CMD ["npm", "start"]
