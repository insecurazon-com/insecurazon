import { defineStore } from 'pinia';
import type { Product, Category } from '@/types'; // Import defined types
import axios from 'axios';

// Make sure API base URL is using the mock endpoints
const API_BASE_URL = 'http://localhost:3000';  // Ensure this matches the ProductController path

// Mock data to use as fallback when API fails
const MOCK_PRODUCTS: Product[] = [
  {
    id: 1,
    name: 'Smartphone X',
    featured: true,
    price: 799.99,
    image: 'https://via.placeholder.com/300?text=Smartphone+X',
    description: 'The latest smartphone with amazing features and long battery life.',
    categoryId: 1,
    fullDescription: 'Experience the future of mobile technology with the Smartphone X. Featuring a stunning 6.5-inch OLED display, powerful octa-core processor, and advanced camera system, this smartphone delivers exceptional performance in a sleek design. With all-day battery life and fast charging capabilities, you can stay connected without interruption.',
    rating: 4.5,
    reviewCount: 127,
    specifications: {
      'Display': '6.5-inch OLED',
      'Processor': 'Octa-core 2.8GHz',
      'RAM': '8GB',
      'Storage': '128GB',
      'Camera': '12MP + 16MP dual rear, 8MP front',
      'Battery': '4500mAh',
      'OS': 'Android 12'
    },
    reviews: [
      { userName: 'John D.', rating: 5, comment: 'Best phone I\'ve ever owned. The battery life is incredible!' },
      { userName: 'Sarah M.', rating: 4, comment: 'Great phone, but a bit expensive.' },
      { userName: 'Michael K.', rating: 4.5, comment: 'Excellent camera quality and fast performance.' }
    ]
  },
  {
    id: 2,
    name: 'Wireless Headphones',
    featured: true,
    price: 149.99,
    image: 'https://via.placeholder.com/300?text=Wireless+Headphones',
    description: 'Premium wireless headphones with noise cancellation.',
    categoryId: 1,
    fullDescription: 'Immerse yourself in superior sound quality with these premium wireless headphones. Featuring advanced noise cancellation technology, these headphones block out ambient noise so you can focus on your music. With cushioned ear cups and an adjustable headband, they provide exceptional comfort for extended listening sessions.',
    rating: 4.7,
    reviewCount: 89,
    specifications: {
      'Type': 'Over-ear',
      'Connectivity': 'Bluetooth 5.0',
      'Battery Life': 'Up to 30 hours',
      'Noise Cancellation': 'Active',
      'Charging': 'USB-C',
      'Weight': '250g'
    },
    reviews: [
      { userName: 'Emily R.', rating: 5, comment: 'The noise cancellation is amazing! Perfect for travel.' },
      { userName: 'David T.', rating: 4.5, comment: 'Great sound quality and comfortable to wear.' }
    ]
  },
  {
    id: 3,
    name: 'Smart Watch',
    featured: true,
    price: 249.99,
    image: 'https://via.placeholder.com/300?text=Smart+Watch',
    description: 'Track your fitness and stay connected with this smart watch.',
    categoryId: 1,
    fullDescription: 'Stay connected and monitor your health with this feature-packed smart watch. Track your steps, heart rate, sleep quality, and more with accurate sensors. Receive notifications, answer calls, and control your music right from your wrist. With a water-resistant design and long battery life, this smart watch is perfect for an active lifestyle.',
    rating: 4.2,
    reviewCount: 64,
    specifications: {
      'Display': '1.4-inch AMOLED',
      'Sensors': 'Heart rate, accelerometer, GPS',
      'Battery Life': 'Up to 7 days',
      'Water Resistance': '5 ATM',
      'Connectivity': 'Bluetooth, Wi-Fi',
      'Compatibility': 'Android, iOS'
    },
    reviews: [
      { userName: 'Robert J.', rating: 4, comment: 'Great fitness tracking features but battery life could be better.' },
      { userName: 'Lisa M.', rating: 5, comment: 'Love how it tracks my workouts and sleep!' }
    ]
  },
  {
    id: 4,
    name: 'Designer T-shirt',
    featured: false,
    price: 39.99,
    image: 'https://via.placeholder.com/300?text=Designer+T-shirt',
    description: 'Comfortable cotton t-shirt with modern design.',
    categoryId: 2,
    fullDescription: 'A very comfortable cotton t-shirt with a modern design, perfect for casual wear.',
    rating: 4.0,
    reviewCount: 25,
    specifications: { 'Material': '100% Cotton', 'Fit': 'Regular' },
    reviews: []
  },
  {
    id: 5,
    name: 'Jeans',
    featured: false,
    price: 59.99,
    image: 'https://via.placeholder.com/300?text=Jeans',
    description: 'Classic jeans with perfect fit and durability.',
    categoryId: 2,
    fullDescription: 'Classic denim jeans that offer both style and durability. A wardrobe essential.',
    rating: 4.3,
    reviewCount: 40,
    specifications: { 'Material': 'Denim', 'Fit': 'Straight Leg' },
    reviews: []
  },
  {
    id: 6,
    name: 'Coffee Maker',
    featured: false,
    price: 99.99,
    image: 'https://via.placeholder.com/300?text=Coffee+Maker',
    description: 'Brew the perfect cup of coffee every morning.',
    categoryId: 3,
    fullDescription: 'Start your day right with this easy-to-use coffee maker. Brews a perfect cup every time.',
    rating: 4.6,
    reviewCount: 70,
    specifications: { 'Capacity': '12 Cups', 'Features': 'Programmable Timer, Auto Shut-off' },
    reviews: []
  }
];

const MOCK_CATEGORIES: Category[] = [
  { id: 1, name: 'Electronics' },
  { id: 2, name: 'Clothing' },
  { id: 3, name: 'Home & Garden' },
  { id: 4, name: 'Books' },
  { id: 5, name: 'Toys' }
];

// Define the state interface
interface ProductState {
  products: Product[];
  categories: Category[];
  loading: boolean;
  error: string | null;
  usingMockData: boolean;
}

export const useProductStore = defineStore('products', {
  // Explicitly type the state
  state: (): ProductState => ({
    products: [],
    categories: [],
    loading: false,
    error: null,
    usingMockData: false
  }),
  getters: {
    // Explicitly type the return values of getters
    allProducts: (state): Product[] => state.products,
    allCategories: (state): Category[] => state.categories,
    featuredProducts: (state): Product[] => state.products.filter(p => p.featured),
    getProductById: (state) => {
      return (productId: number): Product | undefined => 
        state.products.find(product => product.id === productId);
    }
  },
  actions: {
    async fetchProducts() {
      if (this.products.length > 0) return; // Avoid refetching if already populated
      this.loading = true;
      this.error = null;
      try {
        const response = await axios.get<Product[]>(`${API_BASE_URL}/products`);
        this.products = response.data;
        this.usingMockData = false;
      } catch (err) {
        console.error('Failed to fetch products:', err);
        this.error = err instanceof Error ? err.message : 'An unknown error occurred';
        
        // Use mock data as fallback
        console.log('Using mock product data as fallback');
        this.products = MOCK_PRODUCTS;
        this.usingMockData = true;
      } finally {
        this.loading = false;
      }
    },
    async fetchCategories() {
      if (this.categories.length > 0) return; // Avoid refetching
      this.loading = true;
      this.error = null;
      try {
        const response = await axios.get<Category[]>(`${API_BASE_URL}/products/categories`);
        this.categories = response.data;
        this.usingMockData = false;
      } catch (err) {
        console.error('Failed to fetch categories:', err);
        this.error = err instanceof Error ? err.message : 'An unknown error occurred';
        
        // Use mock data as fallback
        console.log('Using mock category data as fallback');
        this.categories = MOCK_CATEGORIES;
        this.usingMockData = true;
      } finally {
        this.loading = false;
      }
    },
    // Action to fetch a single product if needed, though getProductById getter handles it from allProducts
    // async fetchProductById(id: number) {
    //   this.loading = true;
    //   this.error = null;
    //   try {
    //     const response = await axios.get<Product>(`${API_BASE_URL}/products/${id}`);
    //     // Update the specific product in the list or add if not present
    //     const index = this.products.findIndex(p => p.id === id);
    //     if (index !== -1) {
    //       this.products[index] = response.data;
    //     } else {
    //       this.products.push(response.data);
    //     }
    //   } catch (err) {
    //     this.error = err instanceof Error ? err.message : 'An unknown error occurred';
    //     console.error(`Failed to fetch product ${id}:`, err);
    //   } finally {
    //     this.loading = false;
    //   }
    // }
  }
}); 