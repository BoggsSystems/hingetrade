# HingeTrade Client

React frontend for the HingeTrade trading platform.

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Create a `.env` file based on `.env.example`:
   ```bash
   cp .env.example .env
   ```

3. Configure Auth0:
   - Create an Auth0 application
   - Set the callback URL to `http://localhost:3000`
   - Update the `.env` file with your Auth0 credentials

4. Start the development server:
   ```bash
   npm run dev
   ```

## Project Structure

```
src/
├── components/       # Reusable components
│   ├── Auth/        # Authentication components
│   ├── Common/      # Common UI components
│   ├── Layout/      # Layout components
│   └── ...
├── contexts/        # React contexts
├── hooks/           # Custom React hooks
├── pages/           # Page components
├── services/        # API services
├── types/           # TypeScript types
└── utils/           # Utility functions
```

## Features

- **Landing Page**: Hero section with market data and feature showcase
- **Authentication**: Auth0 integration with protected routes
- **Dashboard**: Portfolio overview and market summary
- **Markets**: Asset discovery and search
- **Trading**: Order placement interface
- **Portfolio**: Position management and analytics
- **Alerts**: Price alert configuration

## Styling

The application uses CSS Modules with a dark theme optimized for trading interfaces. The design system includes:

- Dark color palette with high contrast
- Responsive grid layouts
- Reusable component styles
- Trading-specific UI patterns

## API Integration

The client connects to the HingeTrade backend API at `http://localhost:5000`. All API calls are authenticated using JWT tokens from Auth0.
