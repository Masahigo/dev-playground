const dotenv = require('dotenv');
dotenv.config();

// Ensure required ENV vars are set
let requiredEnv = [
	'LINKEDIN_CLIENT_ID', 'LINKEDIN_CLIENT_SECRET',
	'LINKEDIN_REDIRECT_URI'
];
let unsetEnv = requiredEnv.filter((env) => !(typeof process.env[env] !== 'undefined'));
  
if (unsetEnv.length > 0) {
	throw new Error("Required ENV variables are not set: [" + unsetEnv.join(', ') + "]");
}

module.exports = {
	clientID: process.env.LINKEDIN_CLIENT_ID,
	clientSecret: process.env.LINKEDIN_CLIENT_SECRET,
    redirectURI: process.env.LINKEDIN_REDIRECT_URI,

	// ports
	clientPort: 3000,
	serverPort: 9000,
};