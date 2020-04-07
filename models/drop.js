const User = require('./User');
const Account = require('./Account');

User.deleteMany()
  .then(() => {
    console.log('Deleted users');

    Account.deleteMany()
    .then(() => {
      console.log('Deleted accounts');
      process.exit();
    })
  })
