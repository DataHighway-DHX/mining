const express = require('express');
const authMiddleware = require('../middleware/auth');

const router = new express.Router();

// Require controller modules
const usersController = require('../controllers/usersController');

// ROUTES

// POST localhost:7000/users/auth/register
router.post('/auth/register', 
  // Middlware Chain
  (req, res, next) => {
    console.log('Registering user: ', req.body);
    authMiddleware.register(req, res, next);
  },
  (req, res, next) => {
    authMiddleware.signIn;
    next();
  },
  // Handler
  authMiddleware.signJWTForUser
)

// POST localhost:7000/users/auth/login
router.post('/auth/login', 
  // Middlware Chain
  (req, res, next) => {
    console.log('Signin user: ', req.body);
    authMiddleware.signIn;
    next();
  },
  // Handler
  authMiddleware.signJWTForUser
)

// GET localhost:7000/users/show
router.get('/show', 
  (req, res, next) => {
    console.log('Retrieving user nonce for network: ', req.query.network);
    console.log('Retrieving user nonce for publicAddress: ', req.query.publicAddress);
    next();
  },
  usersController.userShowNonce
);

// GET localhost:7000/users/list
router.get('/list', 
  // (req, res, next) => {
  //   console.log('Validating token');
  //   authMiddleware.validateJWTManually,
  //   next();
  // },
  usersController.userList
);

// POST localhost:7000/users/create
router.post('/create',
  (req, res, next) => {
    console.log('Validating token');
    authMiddleware.validateJWTManually,
    next();
  },
  usersController.userCreate
);

module.exports = router;
