export interface Review {
  userName: string;
  rating: number;
  comment: string;
}

export interface Specifications {
  [key: string]: string;
}

export interface Product {
  id: number;
  name: string;
  price: number;
  image: string;
  description: string;
  categoryId: number;
  featured?: boolean;
  fullDescription?: string;
  rating?: number;
  reviewCount?: number;
  specifications?: Specifications;
  reviews?: Review[];
}

export interface Category {
  id: number;
  name: string;
} 