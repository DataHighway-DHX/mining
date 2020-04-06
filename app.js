const expressJwt = require('express-jwt');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
// const authMiddleware = require('./middleware/auth');
const ethUtil = require('ethereumjs-util');
const sigUtil = require('eth-sig-util');
const jwt = require('jsonwebtoken');

// const app = express();

// const usersRouter = require('./routes/users');
// const contractsRouter = require('./routes/contracts');

const attach = function(app, secret) {
  // Don't accept non-AJAX requests to prevent XSRF attacks.
  app.use(function(req, res, next) {
    if (!req.xhr) {
      res.status(500).send('Not AJAX');
    }
    else {
      next();
    }
  });

  // Middleware Plugins
  app.use(bodyParser.json()); // allow JSON uploads
  app.use(cookieParser());
  app.use(bodyParser.urlencoded({ extended: true })); // allow Form submissions

  app.use(
    // authMiddleware.validateJWTExpress
    expressJwt(
      {
        secret: secret,
        credentialsRequired: false,
        getToken: function fromHeaderOrQuerystring (req) {
          return req.cookies.token;
        }
      }
    ).unless({path: ['/users/sign-in']})
  );

  app.post('/', rootRouter);
}


// app.use(authMiddleware.initialize);
// app.use('/users', usersRouter);
// app.use('/contracts', contractsRouter);

// // Routes
// app.get('/', (req, res) => {
//   res.status(404).json({
//     message: 'Error: Server under development'
//   });
// })

module.exports = {
  app,
};
