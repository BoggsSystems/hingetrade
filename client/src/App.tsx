import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from './contexts/AuthContext';
import Layout from './components/Layout/Layout';
import LandingPage from './pages/Landing/LandingPage';
import LoginPage from './pages/Auth/LoginPage';
import RegisterPage from './pages/Auth/RegisterPage';
import OnboardingPage from './pages/Onboarding/OnboardingPage';
import ProtectedRoute from './components/Auth/ProtectedRoute';
import DashboardPage from './pages/Dashboard/DashboardPage';
import MarketsPage from './pages/Markets/MarketsPage';
import PortfolioPage from './pages/Portfolio/PortfolioPage';
import TradingPage from './pages/Trading/TradingPage';
import AlertsPage from './pages/Alerts/AlertsPage';
import TermsOfServicePage from './pages/Legal/TermsOfServicePage';
import PrivacyPolicyPage from './pages/Legal/PrivacyPolicyPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <Router>
          <Routes>
            <Route path="/" element={<LandingPage />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/onboarding" element={<OnboardingPage />} />
            <Route path="/terms" element={<TermsOfServicePage />} />
            <Route path="/privacy" element={<PrivacyPolicyPage />} />
            <Route element={<ProtectedRoute />}>
              <Route element={<Layout />}>
                <Route path="/dashboard" element={<DashboardPage />} />
                <Route path="/markets" element={<MarketsPage />} />
                <Route path="/portfolio" element={<PortfolioPage />} />
                <Route path="/trading" element={<TradingPage />} />
                <Route path="/alerts" element={<AlertsPage />} />
              </Route>
            </Route>
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </Router>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
