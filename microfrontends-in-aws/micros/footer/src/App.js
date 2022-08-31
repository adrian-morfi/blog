import React from 'react';
import { StylesProvider } from '@material-ui/core/styles';
import { BrowserRouter, Switch, Route} from 'react-router-dom';

import StickyFooter from './components/StickyFooter';

export default () => {
  return (
    <div>
      <StylesProvider>
        <BrowserRouter>
          <Switch>
            <Route path="/" component={StickyFooter} />
          </Switch>
        </BrowserRouter>
      </StylesProvider>
    </div>
  );
};
