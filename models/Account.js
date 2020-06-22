const mongoose = require('./init');
const Schema = mongoose.Schema;

const AccountSchema = Schema({
  publicAddress: String,
  nonce: String
});

const Account = mongoose.models.Account || mongoose.model('Account', AccountSchema);

module.exports = Account;
