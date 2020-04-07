const User = require('../models/User');
const Account = require('../models/Account');

// GET index -
const userList = (req, res) => {
  User.find()
    .populate('account')
    .then(users => {
      res.body = users;
      console.log('Authorised: User list returned in response');
      res.json({ data: users });
    })
    .catch(error => res.status(500).json({ error: error.message }))
};

// GET show - nonce
const userShowNonce = (req, res) => {
  console.log('userShowNonce with req.query.network', req.query.network);
  console.log('userShowNonce with req.query.publicAddress', req.query.publicAddress);
  Account.findOne({
    // FIXME - change this so it finds an account with both the given 'network' and 'publicAddress'
    // network: req.query.network,
    publicAddress: req.query.publicAddress
  })
    .then(account => {
      const nonce = account.nonce;
      console.log('Authorised: User account public address nonce returned: ', nonce);
      res.json({ nonce: nonce });
    })
    .catch(error => res.status(500).json({ error: error.message }))
};

// POST create
const userCreate = (req, res) => {
  User.create(req.body)
    .then((user) => {
      res.status(201).json(user).end();
    })
    .catch(error => res.json({ error }))
};

module.exports = {
  userList: userList,
  userShowNonce: userShowNonce,
  userCreate: userCreate
}
