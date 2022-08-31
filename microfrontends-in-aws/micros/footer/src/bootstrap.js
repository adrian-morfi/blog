import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';

const mount = (el) => {
  ReactDOM.render(<App />, el);
};

if (process.env.NODE_ENV === 'development') {
  const devRoot = document.querySelector('#footer_dev_root');

  if (devRoot) 
    mount(devRoot);
  
}

// We are running through container
// and we should export the mount function
export { mount };
