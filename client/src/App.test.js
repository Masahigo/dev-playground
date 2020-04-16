import React from 'react';
import { render } from '@testing-library/react';
import App from './App';

test('renders linked in demo component', () => {
  const { getByText } = render(<App />);
  const linkElement = getByText(/DEMO/i);
  expect(linkElement).toBeInTheDocument();
});
