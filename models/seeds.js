const User = require('./User');
const Account = require('./Account');

let firstAccount = Account.create(
  {
    network: 'ethereum-testnet-local',
    publicAddress: '0x123',
    nonce: '123'
  }
)

User.create(
    [
      {
        email: 'ltfschoen@gmail.com',
        password: '123456',
        name: 'Luke',
        accounts: [firstAccount] 
      }
    ]
  )
  .then((users) => {
    console.log('Created users: ', users);
    process.exit();
  })
  .catch((error) => {
    console.error('Error creating users: ', error);
    process.exit();
  })
