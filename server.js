const { app, attach } = require('./app');

const port = 7000;
attach(
  app.listen(port, (error) => {
    if (error) {
      console.error('Error starting server: ', error);
    } else {
      console.log(`Success starting server http://localhost:${port}/`);
    }
  }),
  "secret"
);