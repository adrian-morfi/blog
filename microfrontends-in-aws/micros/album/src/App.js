import React from 'react';
import { StylesProvider } from '@material-ui/core/styles';
import { BrowserRouter, Switch, Route} from 'react-router-dom';

import Album from './components/Album';

export default () => {
  return (
    <div>
      <StylesProvider>
        <BrowserRouter>
          <Switch>
            <Route path="/" component={Album} />
          </Switch>
        </BrowserRouter>
      </StylesProvider>
    </div>
  );
};
