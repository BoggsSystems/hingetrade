import axios, { type AxiosInstance } from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

class ApiClient {
  private axiosInstance: AxiosInstance;

  constructor() {
    this.axiosInstance = axios.create({
      baseURL: API_BASE_URL,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor to add auth token
    this.axiosInstance.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('authToken');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Response interceptor for error handling
    this.axiosInstance.interceptors.response.use(
      (response) => response,
      async (error) => {
        if (error.response?.status === 401) {
          // Handle unauthorized access
          localStorage.removeItem('authToken');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  get instance() {
    return this.axiosInstance;
  }

  // Account endpoints
  async getAccount() {
    const response = await this.axiosInstance.get('/account');
    return response.data;
  }

  // Positions endpoints
  async getPositions() {
    const response = await this.axiosInstance.get('/positions');
    return response.data;
  }

  // Orders endpoints
  async getOrders(status?: string) {
    const params = status ? { status } : {};
    const response = await this.axiosInstance.get('/orders', { params });
    return response.data;
  }

  async createOrder(orderData: any) {
    const response = await this.axiosInstance.post('/orders', orderData);
    return response.data;
  }

  async cancelOrder(orderId: string) {
    const response = await this.axiosInstance.delete(`/orders/${orderId}`);
    return response.data;
  }

  // Assets endpoints
  async searchAssets(query: string) {
    const response = await this.axiosInstance.get('/assets/search', {
      params: { query },
    });
    return response.data;
  }

  async getAsset(symbol: string) {
    const response = await this.axiosInstance.get(`/assets/${symbol}`);
    return response.data;
  }

  async getMarketHours() {
    const response = await this.axiosInstance.get('/assets/market-hours');
    return response.data;
  }

  // Watchlist endpoints
  async getWatchlists() {
    const response = await this.axiosInstance.get('/watchlists');
    return response.data;
  }

  async createWatchlist(name: string) {
    const response = await this.axiosInstance.post('/watchlists', { name });
    return response.data;
  }

  async addToWatchlist(watchlistId: string, symbol: string) {
    const response = await this.axiosInstance.post(`/watchlists/${watchlistId}/items`, { symbol });
    return response.data;
  }

  async removeFromWatchlist(watchlistId: string, symbol: string) {
    const response = await this.axiosInstance.delete(`/watchlists/${watchlistId}/items/${symbol}`);
    return response.data;
  }

  // Price alerts endpoints
  async getPriceAlerts() {
    const response = await this.axiosInstance.get('/price-alerts');
    return response.data;
  }

  async createPriceAlert(alertData: any) {
    const response = await this.axiosInstance.post('/price-alerts', alertData);
    return response.data;
  }

  async deletePriceAlert(alertId: string) {
    const response = await this.axiosInstance.delete(`/price-alerts/${alertId}`);
    return response.data;
  }

  // Portfolio analytics
  async getPortfolioHistory() {
    const response = await this.axiosInstance.get('/portfolio/history');
    return response.data;
  }

  async getPortfolioAnalytics() {
    const response = await this.axiosInstance.get('/portfolio/analytics');
    return response.data;
  }
}

export const apiClient = new ApiClient();
export default apiClient;