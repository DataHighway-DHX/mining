const express = require('express');
const bodyParser = require('body-parser');
const authMiddleware = require('./middleware/auth');

const app = express();

const usersRouter = require('./routes/users');

// Middleware Plugins
app.use(bodyParser.json()); // allow JSON uploads
app.use(bodyParser.urlencoded({ extended: true })); // allow Form submissions
// app.use(authMiddleware.initialize);
app.use('/users', usersRouter);
app.use((err, req, res, next) => {
  if (err.name === 'UnauthorizedError') {
    res.status(401).send('Invalid token');
  } else {
    next(err);
  }
});

// Routes
app.get('/', (req, res) => {
  res.status(404).json({
    message: 'Error: Server under development'
  });
})

module.exports = app;
