# dataset-preview

for fine-tuning dataset database created by [fintuser](https://github.com/c-v-a-i/fintuser)

## Getting Started

## Prerequisites

1. Set up `.env`.
    ```shell
    cp .env.example .env
    ```
2. Set up the correct node version.
    ```shell
    nvm use
    ```
3. Install the dependencies.
    ```shell
    npm install
    ```
4. Install prisma, then.
    ```shell
    npx prisma generate
    ```
5. Run the database.
    ```shell
    docker-compose up -d
    ```

Should be good to go now


## Development

Run the Vite dev server:

```shell
npm run dev
```

## Deployment

First, build your app for production:

```shell
npm run build
```

Setup your environment:

```shell
NODE_ENV='production'
```

Then run the app in production mode:

```shell
npm start
```

Now you'll need to pick a host to deploy it to.

### DIY

If you're familiar with deploying Node applications, the built-in Remix app server is production-ready.

Make sure to deploy the output of `npm run build` and the server

- `server.js`
- `build/server`
- `build/client`

Take a look at the provided Dockerfile for further details on how to configure a production environment.
