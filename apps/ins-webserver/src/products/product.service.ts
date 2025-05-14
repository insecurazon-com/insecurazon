import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import type { Product, Category } from './product.types';
import axios from 'axios';

@Injectable()
export class ProductService {
  private readonly productServiceUrl: string;

  constructor() {
    // Get product service URL from environment variable or use default
    this.productServiceUrl = process.env.PRODUCT_SERVICE_URL || 'http://localhost:8080';
  }

  async findAllProducts(): Promise<Product[]> {
    try {
      const response = await axios.get<Product[]>(`${this.productServiceUrl}/products`);
      return response.data;
    } catch (error) {
      console.error('Error fetching products:', error);
      // Fallback to empty products array
      return [];
    }
  }

  async findOneProduct(id: number): Promise<Product | undefined> {
    try {
      const response = await axios.get<Product>(`${this.productServiceUrl}/products/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Error fetching product ${id}:`, error);
      return undefined;
    }
  }

  async findAllCategories(): Promise<Category[]> {
    try {
      const response = await axios.get<Category[]>(`${this.productServiceUrl}/products/categories`);
      return response.data;
    } catch (error) {
      console.error('Error fetching categories:', error);
      // Fallback to empty categories array
      return [];
    }
  }
} 