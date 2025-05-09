import { APIGatewayProxyHandler } from 'aws-lambda';
// Import the named handler from main.ts
import { handler as mainHandler } from './main';

// The mainHandler from main.ts is already configured and ready to be used.
// No need to re-bootstrap or re-wrap with serverlessExpress here.

export const handler: APIGatewayProxyHandler = mainHandler; 