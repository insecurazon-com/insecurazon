<template>
  <div>
    <v-container>
      <h1 class="text-h4 mb-6">Shopping Cart</h1>
      
      <v-row v-if="cartItems.length > 0">
        <v-col cols="12" md="8">
          <v-card>
            <v-list>
              <v-list-item
                v-for="(item, index) in cartItems"
                :key="index"
                :title="item.product.name"
                :subtitle="`$${item.product.price.toFixed(2)}`"
              >
                <template v-slot:prepend>
                  <v-avatar size="80" rounded>
                    <v-img :src="item.product.image" cover></v-img>
                  </v-avatar>
                </template>
                
                <template v-slot:append>
                  <div class="d-flex align-center">
                    <v-btn
                      icon
                      variant="text"
                      density="comfortable"
                      @click="decreaseQuantity(index)"
                      :disabled="item.quantity <= 1"
                    >
                      <v-icon>mdi-minus</v-icon>
                    </v-btn>
                    
                    <span class="mx-2">{{ item.quantity }}</span>
                    
                    <v-btn
                      icon
                      variant="text"
                      density="comfortable"
                      @click="increaseQuantity(index)"
                    >
                      <v-icon>mdi-plus</v-icon>
                    </v-btn>
                    
                    <v-btn
                      icon
                      color="error"
                      variant="text"
                      class="ml-4"
                      @click="removeItem(index)"
                    >
                      <v-icon>mdi-delete</v-icon>
                    </v-btn>
                  </div>
                </template>
              </v-list-item>
            </v-list>
            
            <v-divider></v-divider>
            
            <v-card-actions>
              <v-btn
                prepend-icon="mdi-arrow-left"
                to="/products"
                variant="text"
              >
                Continue Shopping
              </v-btn>
              <v-spacer></v-spacer>
              <v-btn
                color="error"
                variant="text"
                prepend-icon="mdi-delete-sweep"
                @click="clearCart"
              >
                Clear Cart
              </v-btn>
            </v-card-actions>
          </v-card>
        </v-col>
        
        <v-col cols="12" md="4">
          <v-card>
            <v-card-title>Order Summary</v-card-title>
            <v-card-text>
              <div class="d-flex justify-space-between mb-2">
                <span>Subtotal ({{ totalItems }} items):</span>
                <span>${{ subtotal.toFixed(2) }}</span>
              </div>
              <div class="d-flex justify-space-between mb-2">
                <span>Shipping:</span>
                <span>{{ shipping > 0 ? '$' + shipping.toFixed(2) : 'FREE' }}</span>
              </div>
              <div class="d-flex justify-space-between mb-2">
                <span>Tax (8%):</span>
                <span>${{ tax.toFixed(2) }}</span>
              </div>
              
              <v-divider class="my-4"></v-divider>
              
              <div class="d-flex justify-space-between text-h6">
                <span>Total:</span>
                <span>${{ total.toFixed(2) }}</span>
              </div>
              
              <v-btn
                color="primary"
                block
                size="large"
                class="mt-6"
                :to="'/checkout'"
              >
                Proceed to Checkout
              </v-btn>
            </v-card-text>
          </v-card>
          
          <v-card class="mt-4">
            <v-card-text>
              <h3 class="text-subtitle-1 mb-2">We Accept</h3>
              <div class="d-flex flex-wrap">
                <v-icon class="ma-1" size="large">mdi-credit-card</v-icon>
                <v-icon class="ma-1" size="large">mdi-credit-card-outline</v-icon>
                <v-icon class="ma-1" size="large">mdi-paypal</v-icon>
                <v-icon class="ma-1" size="large">mdi-bank</v-icon>
              </div>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
      
      <v-row v-else>
        <v-col cols="12" class="text-center">
          <v-icon size="x-large" color="grey" class="mb-4">mdi-cart-outline</v-icon>
          <h2 class="text-h5 mb-4">Your cart is empty</h2>
          <p class="mb-6">Looks like you haven't added any products to your cart yet.</p>
          <v-btn
            color="primary"
            size="large"
            to="/products"
          >
            Start Shopping
          </v-btn>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script lang="ts">
export default {
  name: 'CartPage',
  data() {
    return {
      // Mock cart data - in a real app, this would be stored in Vuex/Pinia or a similar state management solution
      cartItems: [
        {
          product: {
            id: 1,
            name: 'Smartphone X',
            price: 799.99,
            image: 'https://via.placeholder.com/300?text=Smartphone+X'
          },
          quantity: 1
        },
        {
          product: {
            id: 2,
            name: 'Wireless Headphones',
            price: 149.99,
            image: 'https://via.placeholder.com/300?text=Wireless+Headphones'
          },
          quantity: 2
        }
      ]
    }
  },
  computed: {
    totalItems() {
      return this.cartItems.reduce((total, item) => total + item.quantity, 0);
    },
    subtotal() {
      return this.cartItems.reduce((total, item) => total + (item.product.price * item.quantity), 0);
    },
    shipping() {
      // Free shipping over $50
      return this.subtotal >= 50 ? 0 : 5.99;
    },
    tax() {
      return this.subtotal * 0.08; // 8% tax rate
    },
    total() {
      return this.subtotal + this.shipping + this.tax;
    }
  },
  methods: {
    increaseQuantity(index: any) {
      this.cartItems[index].quantity++;
    },
    decreaseQuantity(index: any) {
      if (this.cartItems[index].quantity > 1) {
        this.cartItems[index].quantity--;
      }
    },
    removeItem(index: any) {
      this.cartItems.splice(index, 1);
    },
    clearCart() {
      this.cartItems = [];
    }
  }
}
</script> 