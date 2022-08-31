import React from 'react';
import { StylesProvider } from '@material-ui/core/styles';
import { BrowserRouter, Switch, Route} from 'react-router-dom';

import NavBar from './components/NavBar';

export default () => {
  return (
    <div>
      <StylesProvider>
        <BrowserRouter>
          <Switch>
            <Route path="/" component={NavBar} />
          </Switch>
        </BrowserRouter>
      </StylesProvider>
    </div>
  );
};
