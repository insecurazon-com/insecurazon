import { Module, NestModule, MiddlewareConsumer, RequestMethod } from '@nestjs/common';
import { AppController } from './app.controller';
import { ApiProxyService } from './services/api-proxy.service';
import { ProductModule } from './products/product.module';

// Create a middleware function to divert /products routes early
import { NextFunction, Request, Response } from 'express';

// Middleware to add debug information for routing
export function productRoutingMiddleware(req: Request, res: Response, next: NextFunction) {
  if (req.path.startsWith('/products')) {
    console.log(`[DEBUG] Received request for ${req.path}, directing to ProductController`);
  }
  next();
}

@Module({
  imports: [ProductModule],
  controllers: [AppController],
  providers: [ApiProxyService],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    // Apply our routing debug middleware to all routes
    consumer
      .apply(productRoutingMiddleware)
      .forRoutes('*');
  }
} 