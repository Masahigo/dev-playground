import React from 'react';
import logo from './images/logo.png'; // Tell webpack this JS file uses this image
import "./Logo.css";

function Logo() {
  return (
    <div id="logo-wrapper">
      <img src={logo} alt="Dev Playground logo" />
    </div>
  );
}

export default Logo;