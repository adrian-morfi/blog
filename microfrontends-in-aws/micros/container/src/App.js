import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import {
  StylesProvider,
  createGenerateClassName,
} from '@material-ui/core/styles';

import HeaderApp from './components/HeaderApp';
import AlbumApp from './components/AlbumApp';
import FooterApp from './components/FooterApp';

const generateClassName = createGenerateClassName({
  productionPrefix: 'co',
});

export default () => {
  return (
    <BrowserRouter>
      <StylesProvider generateClassName={generateClassName}>
        <div>
          <HeaderApp />
          <AlbumApp />
          <FooterApp />
        </div>
      </StylesProvider>
    </BrowserRouter>
  );
};
