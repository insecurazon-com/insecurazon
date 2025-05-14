import { Controller, Get, Param, NotFoundException, ParseIntPipe, Header } from '@nestjs/common';
import { ProductService } from './product.service';
import type { Product, Category } from './product.types';

@Controller('products')
export class ProductController {
  constructor(private readonly productService: ProductService) {}

  @Get()
  @Header('Content-Type', 'application/json') // Force JSON content type
  async findAllProducts(): Promise<Product[]> {
    console.log('Serving products from ProductController');
    return this.productService.findAllProducts();
  }

  @Get('categories') // Route for products/categories
  @Header('Content-Type', 'application/json') // Force JSON content type
  async findAllCategories(): Promise<Category[]> {
    console.log('Serving categories from ProductController');
    return this.productService.findAllCategories();
  }

  @Get(':id')
  @Header('Content-Type', 'application/json') // Force JSON content type
  async findOneProduct(@Param('id', ParseIntPipe) id: number): Promise<Product> {
    console.log(`Serving product ${id} from ProductController`);
    const product = await this.productService.findOneProduct(id);
    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }
    return product;
  }
}