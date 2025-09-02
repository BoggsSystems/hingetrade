import { NextRequest, NextResponse } from 'next/server';
import { jwtVerify } from 'jose';

const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-key-that-is-at-least-32-characters-long';

// Routes that require authentication
const protectedRoutes = [
  '/dashboard',
  '/videos',
  '/upload',
  '/analytics',
  '/settings',
  '/profile'
];

// Routes that redirect to dashboard if already authenticated
const authRoutes = ['/login', '/register'];

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  console.log('🔒 Middleware checking path:', pathname);
  
  // TEMPORARILY DISABLE MIDDLEWARE FOR TESTING
  return NextResponse.next();
  
  // Check if route needs protection
  const isProtectedRoute = protectedRoutes.some(route => pathname.startsWith(route));
  const isAuthRoute = authRoutes.includes(pathname);
  
  console.log('🛡️ Route protection status:', { isProtectedRoute, isAuthRoute });
  
  if (!isProtectedRoute && !isAuthRoute) {
    return NextResponse.next();
  }

  // Get token from Authorization header or fallback to cookie
  const authHeader = request.headers.get('authorization');
  let token = authHeader?.replace('Bearer ', '');
  
  if (!token) {
    // Try to get from cookie (for SSR pages)
    token = request.cookies.get('accessToken')?.value;
  }
  
  console.log('🔑 Token found:', !!token);

  let isValidToken = false;
  
  if (token) {
    try {
      // Since we're storing JWT tokens from the API, try to decode and validate them
      const secret = new TextEncoder().encode(JWT_SECRET);
      await jwtVerify(token, secret, {
        issuer: 'CreatorStudio',
        audience: 'CreatorStudio',
      });
      isValidToken = true;
      console.log('✅ Token is valid');
    } catch (error) {
      // If JWT validation fails, check if it's a simple token by trying to decode it
      try {
        // Try to decode as base64 JWT payload (basic validation)
        const parts = token.split('.');
        if (parts.length === 3) {
          const payload = JSON.parse(atob(parts[1]));
          // Check if token is not expired
          if (payload.exp && payload.exp > Date.now() / 1000) {
            isValidToken = true;
            console.log('✅ JWT token is valid (fallback validation)');
          } else {
            console.log('❌ JWT token is expired');
          }
        } else {
          // For now, accept any non-empty token (temporary)
          isValidToken = true;
          console.log('🔄 Using simple token validation (temporary)');
        }
      } catch (decodeError) {
        console.log('❌ Token validation failed:', error);
        isValidToken = false;
      }
    }
  }

  // Handle protected routes
  if (isProtectedRoute && !isValidToken) {
    console.log('🚫 Redirecting to home due to invalid token');
    const url = new URL('/', request.url);
    url.searchParams.set('redirect', pathname);
    return NextResponse.redirect(url);
  }

  // Handle auth routes (redirect to dashboard if already logged in)
  if (isAuthRoute && isValidToken) {
    console.log('🏠 Redirecting to dashboard');
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     */
    '/((?!api|_next/static|_next/image|favicon.ico|public).*)',
  ],
};