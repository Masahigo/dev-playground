import React, { Component } from 'react';
import QueryString from 'query-string';
import { LinkedInPopUp } from 'react-linkedin-login-oauth2';
import LinkedInPage from './LinkedInPage';

class Demo extends Component {
  render() {
    const params = QueryString.parse(window.location.search);
    if (params.code || params.error) {
      return (
        <LinkedInPopUp />
      );
    }
    return (
      <LinkedInPage />
    );
  }
}
export default Demo;