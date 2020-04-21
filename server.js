const express = require('express');
const cors = require('cors');
var compression = require('compression')
const config = require('./config');
const { URLSearchParams } = require('url')
const fetch = require('node-fetch')

const app = express();

const LINKEDIN_ACCESS_TOKEN = 'https://www.linkedin.com/oauth/v2/accessToken'
const LINKEDIN_NAME_URL = 'https://api.linkedin.com/v2/me'
const LINKEDIN_PHOTO_URL = 'https://api.linkedin.com/v2/me?projection=(id,profilePicture(displayImage~:playableStreams))'

const fetchJSON = (...args) => fetch(...args).then(r => r.json())

// Use gzip compression
app.use(compression());

// configure CORS
app.use(cors(
    {
        origin: true,
        credentials: true
    })
);

app.get('/linkedin', async (req, res) => {
    if(!req.query.code) {
        return res
            .status(400)
            .send(
                `No auth code provided!`
            );
    }
    try {
        const body = new URLSearchParams({
            grant_type: 'authorization_code',
            code: req.query.code,
            redirect_uri: config.redirectURI,
            client_id: config.clientID,
            client_secret: config.clientSecret
        })
        const { access_token } = await fetchJSON(LINKEDIN_ACCESS_TOKEN, {
            method: 'POST',
            body
        })
        const payload = {
            method: 'GET',
            headers: { Authorization: `Bearer ${access_token}` }
        }
        const { localizedFirstName, localizedLastName } = await fetchJSON(
            LINKEDIN_NAME_URL,
            payload
        )
        const { profilePicture } = await fetchJSON(LINKEDIN_PHOTO_URL, payload)

        res.send({
            name: `${localizedFirstName} ${localizedLastName}`,
            picture: profilePicture['displayImage~'].elements[0].identifiers[0].identifier
        });

    } catch (error) {
        console.log(error)
    }
})

// start server
app.listen(config.serverPort, () => console.log(`Express backend listening on port ${config.serverPort}.`));