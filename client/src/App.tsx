import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Auth0Provider } from '@auth0/auth0-react';
import { AuthProvider } from './contexts/AuthContext';
import Layout from './components/Layout/Layout';
import LandingPage from './pages/Landing/LandingPage';
import ProtectedRoute from './components/Auth/ProtectedRoute';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});

// TODO: Replace these with your actual Auth0 configuration
const auth0Domain = import.meta.env.VITE_AUTH0_DOMAIN || 'your-domain.auth0.com';
const auth0ClientId = import.meta.env.VITE_AUTH0_CLIENT_ID || 'your-client-id';
const auth0Audience = import.meta.env.VITE_AUTH0_AUDIENCE || 'your-api-audience';

function App() {
  return (
    <Auth0Provider
      domain={auth0Domain}
      clientId={auth0ClientId}
      authorizationParams={{
        redirect_uri: window.location.origin,
        audience: auth0Audience,
      }}
    >
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <Router>
            <Routes>
              <Route path="/" element={<LandingPage />} />
              <Route element={<ProtectedRoute />}>
                <Route element={<Layout />}>
                  <Route path="/dashboard" element={<div>Dashboard (TODO)</div>} />
                  <Route path="/markets" element={<div>Markets (TODO)</div>} />
                  <Route path="/portfolio" element={<div>Portfolio (TODO)</div>} />
                  <Route path="/trading" element={<div>Trading (TODO)</div>} />
                  <Route path="/alerts" element={<div>Alerts (TODO)</div>} />
                </Route>
              </Route>
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </Router>
        </AuthProvider>
      </QueryClientProvider>
    </Auth0Provider>
  );
}

export default App;
