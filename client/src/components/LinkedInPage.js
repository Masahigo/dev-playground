import React, { Component } from 'react';
import { LinkedIn } from 'react-linkedin-login-oauth2';
import Button from '@material-ui/core/Button';

class LinkedInPage extends Component {
  state = {
    name: '',
    pictureUrl: '',
    code: '',
    errorMessage: '',
    isLoggedIn: false,
  };

  handleSuccess = (data) => {
      this.setState({ 
        code: data.code,
        errorMessage: '',
        isLoggedIn: true,
      });

      (async () => {
        const response = await fetch(process.env.REACT_APP_BACKEND_URL+'/linkedin?code='+data.code);
        const body = await response.json();
        if (response.status !== 200) throw Error(body.message);
        this.setState({ name: body.name })
        this.setState({ pictureUrl: body.picture })
      })();
  }

  handleFailure = (error) => {
    this.setState({
      name: '',
      pictureUrl: '',
      code: '',
      errorMessage: error.errorMessage,
      isLoggedIn: false,
    });
  }

 logout() {
    localStorage.clear();
    this.setState({
      name: '',
      pictureUrl: '',
      code: '',
      errorMessage: '',
      isLoggedIn: false,
    });
  }
  
  render() {
    const { name, pictureUrl, errorMessage, isLoggedIn } = this.state;
    
    return (
      <div>
        {isLoggedIn ? null : (
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
          )
        }
        {pictureUrl && <div><img src={pictureUrl} alt="LI profile pic" /></div>}
        {name && <div>{name}</div>}
        {errorMessage && <div>{errorMessage}</div>}
        {isLoggedIn && <Button variant="outlined" color="primary" onClick={() => { this.logout() }}>Logout</Button>}
      </div>
    );
  }
}

export default LinkedInPage;