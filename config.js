const dotenv = require('dotenv');
dotenv.config();
module.exports = {
	clientID: process.env.LINKEDIN_CLIENT_ID,
	clientSecret: process.env.LINKEDIN_CLIENT_SECRET,
    redirectURI: process.env.LINKEDIN_REDIRECT_URI,
    clientAppURL: process.env.REACT_APP_URL,

	// ports
	clientPort: 3000,
	serverPort: 9000,
};