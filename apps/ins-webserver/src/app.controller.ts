import { Controller, Get, All, Req, Res, Next } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { ApiProxyService } from './services/api-proxy.service';
import * as path from 'path';
import * as fs from 'fs';

@Controller()
export class AppController {
  private readonly staticFilesPath: string;

  constructor(private readonly apiProxyService: ApiProxyService) {
    // Path to the built Vue application
    // In a real Lambda deployment, this would be part of the Lambda package
    this.staticFilesPath = process.env.STATIC_FILES_PATH || 
      path.join(__dirname, '../../ins-webfe/dist');
  }

  // Proxy API requests to the backend EXCEPT /mock/products/* which are handled by ProductController
  @All('api/*')
  async proxyApiRequest(
    @Req() req: Request, 
    @Res() res: Response, 
    @Next() next: NextFunction
  ) {
    // Skip proxying /api/products routes - let ProductController handle them
    if (req.path.startsWith('/api/products')) {
      // Pass control to the next handler (ProductController)
      return next();
    }
    
    // For all other /api routes, proxy to external API
    return this.apiProxyService.forwardRequest(req, res);
  }

  // Serve the Vue SPA for all other routes EXCEPT /mock/products paths
  @Get('*')
  serveStaticFile(@Req() req: Request, @Res() res: Response, @Next() next: NextFunction) {
    // Skip requests to /mock/products endpoints - let ProductController handle them
    if (req.path.startsWith('/mock/products')) {
      console.log(`[DEBUG] Skipping SPA serving for ${req.path}, delegating to ProductController`);
      return next();
    }

    // Get the requested path or default to index.html
    let requestPath = req.path;
    
    // Remove leading slash
    if (requestPath.startsWith('/')) {
      requestPath = requestPath.substring(1);
    }
    
    // If path is empty or is a route path (doesn't have a file extension)
    // serve the index.html file (for SPA routing)
    if (requestPath === '' || !path.extname(requestPath)) {
      requestPath = 'index.html';
    }
    
    const filePath = path.join(this.staticFilesPath, requestPath);
    
    // Check if file exists
    if (fs.existsSync(filePath)) {
      // Set appropriate content type based on file extension
      const ext = path.extname(filePath).toLowerCase();
      const contentType = this.getContentType(ext);
      if (contentType) {
        res.setHeader('Content-Type', contentType);
      }
      
      // Stream the file to the response
      fs.createReadStream(filePath).pipe(res);
    } else {
      // If file doesn't exist and we're not serving index.html already,
      // serve index.html for client-side routing
      if (requestPath !== 'index.html') {
        const indexPath = path.join(this.staticFilesPath, 'index.html');
        if (fs.existsSync(indexPath)) {
          res.setHeader('Content-Type', 'text/html');
          fs.createReadStream(indexPath).pipe(res);
        } else {
          res.status(404).send('Not Found');
        }
      } else {
        res.status(404).send('Not Found');
      }
    }
  }
  
  private getContentType(ext: string): string | null {
    const contentTypes = {
      '.html': 'text/html',
      '.js': 'text/javascript',
      '.css': 'text/css',
      '.json': 'application/json',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.gif': 'image/gif',
      '.svg': 'image/svg+xml',
      '.ico': 'image/x-icon',
    };
    
    return contentTypes[ext] || null;
  }
} 