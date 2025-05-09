import axios from 'axios';

const API_URL = process.env.API_URL || 'https://api.insecurazon.local';

const api = axios.create({
  baseURL: API_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
});

// Request interceptor for adding auth token
api.interceptors.request.use(
  config => {
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  error => {
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  response => response,
  error => {
    if (error.response && error.response.status === 401) {
      // Handle unauthorized errors (e.g., redirect to login)
      localStorage.removeItem('auth_token');
      // In a real app, we would redirect to login page or show a login modal
    }
    return Promise.reject(error);
  }
);

export const productService = {
  getAllProducts() {
    return api.get('/products');
  },
  
  getProductById(id) {
    return api.get(`/products/${id}`);
  },
  
  searchProducts(query) {
    return api.get(`/products/search?q=${query}`);
  },
  
  getProductsByCategory(categoryId) {
    return api.get(`/products/category/${categoryId}`);
  }
};

export const cartService = {
  getCart() {
    return api.get('/cart');
  },
  
  addToCart(productId, quantity = 1) {
    return api.post('/cart/items', { productId, quantity });
  },
  
  updateCartItem(itemId, quantity) {
    return api.put(`/cart/items/${itemId}`, { quantity });
  },
  
  removeCartItem(itemId) {
    return api.delete(`/cart/items/${itemId}`);
  },
  
  clearCart() {
    return api.delete('/cart');
  }
};

export const orderService = {
  placeOrder(orderData) {
    return api.post('/orders', orderData);
  },
  
  getOrderById(id) {
    return api.get(`/orders/${id}`);
  },
  
  getOrderHistory() {
    return api.get('/orders/history');
  }
};

export const userService = {
  login(credentials) {
    return api.post('/auth/login', credentials);
  },
  
  register(userData) {
    return api.post('/auth/register', userData);
  },
  
  getUserProfile() {
    return api.get('/users/profile');
  },
  
  updateUserProfile(profileData) {
    return api.put('/users/profile', profileData);
  }
};

export default api; 