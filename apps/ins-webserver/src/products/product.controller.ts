import { Controller, Get, Param, NotFoundException, ParseIntPipe, Header } from '@nestjs/common';
import { ProductService } from './product.service';
import type { Product, Category } from './product.types';

@Controller('mock/products') // Changed from 'api/products' to 'mock/products' 
export class ProductController {
  constructor(private readonly productService: ProductService) {}

  @Get()
  @Header('Content-Type', 'application/json') // Force JSON content type
  findAllProducts(): Product[] {
    console.log('Serving mock products from ProductController');
    return this.productService.findAllProducts();
  }

  @Get('categories') // Route for /mock/products/categories
  @Header('Content-Type', 'application/json') // Force JSON content type
  findAllCategories(): Category[] {
    console.log('Serving mock categories from ProductController');
    return this.productService.findAllCategories();
  }

  @Get(':id')
  @Header('Content-Type', 'application/json') // Force JSON content type
  findOneProduct(@Param('id', ParseIntPipe) id: number): Product {
    console.log(`Serving mock product ${id} from ProductController`);
    const product = this.productService.findOneProduct(id);
    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }
    return product;
  }
} 