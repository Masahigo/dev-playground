import React, { Component } from 'react';
import { LinkedIn } from 'react-linkedin-login-oauth2';

class LinkedInPage extends Component {
  state = {
    code: '',
    errorMessage: '',
    isLoggedIn: false,
  };


  handleSuccess = (data) => {
    console.log("data: " + data)
    this.setState({
      code: data.code,
      errorMessage: '',
      isLoggedIn: true,
    });
  }

  handleFailure = (error) => {
    this.setState({
      code: '',
      errorMessage: error.errorMessage,
      isLoggedIn: false,
    });
  }
  
  render() {
    const { code, errorMessage, isLoggedIn } = this.state;
    
    return (
      <div>
        <LinkedIn
          clientId={process.env.REACT_APP_LINKEDIN_CLIENT_ID}
          scope="r_liteprofile"
          state={process.env.REACT_APP_LINKEDIN_STATE}
          onFailure={this.handleFailure}
          onSuccess={this.handleSuccess}
          redirectUri={process.env.REACT_APP_LINKEDIN_REDIRECT_URI}
        >
          <img src={require('../images/linkedin.png')} alt="Log in with Linked In" style={{ maxWidth: '180px' }} />
        </LinkedIn>
        {!code && <div>No code</div>}
        {code && <div>Code: {code}</div>}
        {errorMessage && <div>{errorMessage}</div>}
        {isLoggedIn && <div><a href="#" title="Logout from LinkedIn">Logout</a></div>}
      </div>
    );
  }
}

export default LinkedInPage;