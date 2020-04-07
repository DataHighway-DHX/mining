const mongoose = require('./init');
const Schema = mongoose.Schema;
const ObjectId = Schema.Types.ObjectId;
const passportLocalMongoose = require('passport-local-mongoose');

const AccountRef = {
  type: ObjectId, ref: 'Account'
}

const UserSchema = Schema({
  name: String,
  accounts: [{ account: AccountRef }]
});

// Plugin to add Passport email/password credentials to the UserSchema
// and adds Passport methods including `register`
UserSchema.plugin(passportLocalMongoose, {
  usernameField: 'email', // Override login field to be email instead
  usernameLowerCase: true, // Ensure all emails are lowercase
  session: false // Disable session cookies since we will use JWTs
})

UserSchema.methods.fullName = function() {
  return `${this.name}`;
}

const User = mongoose.models.User || mongoose.model('User', UserSchema);

module.exports = User;
