# Backend application (Node.JS + Express) for SPA demo

This is a simple backend app for fetching user's data from LinkedIn API. The client app calls this by providing the needed authorization code since it handles the login part.

## Running the SPA demo locally

```bash
npm install
cd client
npm install
cd ..
npm run dev
```

## Building the Docker image and pushing to Docker Hub

```bash
# Sign in to Docker Hub
docker login
docker build -t masahigo/spa-demo-backend .
docker push masahigo/spa-demo-backend
```