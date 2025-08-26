// Asset types
export type AssetClass = 'us_equity' | 'crypto';

export interface Asset {
  id: string;
  class: AssetClass;
  symbol: string;
  name: string;
  exchange?: string;
  status: string;
  tradable: boolean;
  marginable: boolean;
  shortable: boolean;
  easyToBorrow: boolean;
  fractionable: boolean;
  price?: number;
  changePercent?: number;
  volume?: number;
  marketCap?: number;
}

// Order types
export type OrderSide = 'buy' | 'sell';
export type OrderType = 'market' | 'limit' | 'stop' | 'stop_limit';
export type OrderTimeInForce = 'day' | 'gtc' | 'opg' | 'cls' | 'ioc' | 'fok';
export type OrderStatus = 'new' | 'partially_filled' | 'filled' | 'done_for_day' | 'canceled' | 'expired' | 'replaced' | 'pending_cancel' | 'pending_replace' | 'accepted' | 'pending_new' | 'accepted_for_bidding' | 'stopped' | 'rejected' | 'suspended' | 'calculated';

export interface Order {
  id: string;
  clientOrderId?: string;
  createdAt: string;
  updatedAt?: string;
  submittedAt?: string;
  filledAt?: string;
  expiredAt?: string;
  canceledAt?: string;
  failedAt?: string;
  replacedAt?: string;
  replacedBy?: string;
  replaces?: string;
  assetId: string;
  symbol: string;
  assetClass: AssetClass;
  qty?: string;
  filledQty?: string;
  notional?: string;
  filledAvgPrice?: string;
  side: OrderSide;
  type: OrderType;
  timeInForce: OrderTimeInForce;
  limitPrice?: string;
  stopPrice?: string;
  status: OrderStatus;
  extendedHours: boolean;
  legs?: Order[];
}

// Position types
export interface Position {
  assetId: string;
  symbol: string;
  exchange: string;
  assetClass: AssetClass;
  avgEntryPrice: string;
  qty: string;
  side: 'long' | 'short';
  marketValue: string;
  costBasis: string;
  unrealizedPl?: string;
  unrealizedPlpc?: string;
  unrealizedIntradayPl?: string;
  unrealizedIntradayPlpc?: string;
  currentPrice?: string;
  lastdayPrice?: string;
  changeToday?: string;
}

// Account types
export interface Account {
  id: string;
  accountNumber: string;
  status: string;
  currency: string;
  buyingPower: string;
  cash: string;
  portfolioValue: string;
  patternDayTrader: boolean;
  tradingBlocked: boolean;
  transfersBlocked: boolean;
  accountBlocked: boolean;
  tradeSuspendedByUser: boolean;
  multiplier: string;
  shortingEnabled: boolean;
  equity: string;
  lastEquity: string;
  longMarketValue: string;
  shortMarketValue: string;
  initialMargin: string;
  maintenanceMargin: string;
  lastMaintenanceMargin: string;
  sma: string;
  daytradeCount: number;
}

// Watchlist types
export interface Watchlist {
  id: string;
  accountId: string;
  createdAt: string;
  updatedAt: string;
  name: string;
  items: string[];
}

// Alert types
export interface PriceAlert {
  id: string;
  symbol: string;
  price: number;
  condition: 'above' | 'below';
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  triggeredAt?: string;
}

// Market data types
export interface Bar {
  t: string; // timestamp
  o: number; // open
  h: number; // high
  l: number; // low
  c: number; // close
  v: number; // volume
  n?: number; // number of trades
  vw?: number; // volume weighted average price
}

export interface Quote {
  symbol: string;
  timestamp: string;
  askPrice: number;
  askSize: number;
  bidPrice: number;
  bidSize: number;
  lastPrice: number;
  lastSize: number;
}

// Market hours
export interface MarketHours {
  date: string;
  isOpen: boolean;
  openTime?: string;
  closeTime?: string;
  earlyOpenTime?: string;
  lateCloseTime?: string;
}

// Portfolio analytics
export interface PortfolioHistory {
  timestamp: string;
  equity: number;
  profitLoss: number;
  profitLossPercent: number;
  baseValue: number;
  timeframe: string;
}

export interface PortfolioAnalytics {
  totalReturn: number;
  totalReturnPercent: number;
  dailyReturn: number;
  dailyReturnPercent: number;
  volatility: number;
  sharpeRatio: number;
  maxDrawdown: number;
  winRate: number;
  averageWin: number;
  averageLoss: number;
  profitFactor: number;
  sectorAllocation: Record<string, number>;
  assetClassAllocation: Record<string, number>;
}

// User types
export type KycStatus = 'NotStarted' | 'InProgress' | 'UnderReview' | 'Approved' | 'Rejected' | 'Expired';

export interface User {
  id: string;
  email: string;
  username: string;
  emailVerified: boolean;
  kycStatus: KycStatus;
  kycSubmittedAt?: string;
  kycApprovedAt?: string;
  createdAt: string;
  roles: string[];
}

// Form types
export interface OrderFormData {
  symbol: string;
  side: OrderSide;
  type: OrderType;
  qty?: string;
  notional?: string;
  timeInForce: OrderTimeInForce;
  limitPrice?: string;
  stopPrice?: string;
  extendedHours: boolean;
}