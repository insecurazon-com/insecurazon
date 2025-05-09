import { Injectable } from '@nestjs/common';
import { Request, Response } from 'express';
import axios, { AxiosRequestConfig } from 'axios';

@Injectable()
export class ApiProxyService {
  private readonly apiGatewayUrl: string;

  constructor() {
    // Get API Gateway URL from environment variable
    this.apiGatewayUrl = process.env.API_GATEWAY_URL || 'https://api.insecurazon.local';
  }

  async forwardRequest(req: Request, res: Response): Promise<void> {
    try {
      // Extract API path from the original URL (remove the '/api' prefix)
      const apiPath = req.url.replace(/^\/api/, '');
      
      // Build target URL
      const targetUrl = `${this.apiGatewayUrl}${apiPath}`;
      
      // Prepare Axios request config
      const config: AxiosRequestConfig = {
        method: req.method as any,
        url: targetUrl,
        headers: this.getForwardHeaders(req),
        data: req.body,
        params: req.query,
        responseType: 'stream'
      };
      
      // Make the request to the API Gateway
      const apiResponse = await axios(config);
      
      // Set response status and headers
      res.status(apiResponse.status);
      
      Object.entries(apiResponse.headers).forEach(([key, value]) => {
        // Skip setting content-length as it might be modified
        if (key.toLowerCase() !== 'content-length') {
          res.setHeader(key, value as string);
        }
      });
      
      // Pipe the response back to the client
      apiResponse.data.pipe(res);
    } catch (error) {
      // Handle errors
      this.handleProxyError(error, res);
    }
  }
  
  private getForwardHeaders(req: Request): Record<string, any> {
    const headers: Record<string, any> = {};
    
    // Copy original headers, excluding some that should be set by Axios
    Object.entries(req.headers).forEach(([key, value]) => {
      const lowerKey = key.toLowerCase();
      
      // Skip headers that should not be forwarded
      if (
        lowerKey !== 'host' &&
        lowerKey !== 'connection' &&
        lowerKey !== 'content-length'
      ) {
        headers[key] = value;
      }
    });
    
    // Add real client IP if available (e.g., from Lambda event)
    if (req.ip) {
      headers['X-Forwarded-For'] = req.ip;
    }
    
    return headers;
  }
  
  private handleProxyError(error: any, res: Response): void {
    console.error('API Proxy Error:', error.message);
    
    // If we have an axios error with a response, use that
    if (error.response) {
      res.status(error.response.status);
      
      // Set response headers
      Object.entries(error.response.headers).forEach(([key, value]) => {
        if (key.toLowerCase() !== 'content-length') {
          res.setHeader(key, value as string);
        }
      });
      
      // If the error response is a stream, pipe it
      if (error.response.data && typeof error.response.data.pipe === 'function') {
        error.response.data.pipe(res);
        return;
      }
      
      // Otherwise send the data as is
      res.send(error.response.data);
    } else {
      // Generic error response
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'An error occurred while processing your request'
      });
    }
  }
} 