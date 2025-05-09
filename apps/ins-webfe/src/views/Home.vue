<template>
  <v-container fluid>
    <!-- Mock Data Alert Banner -->
    <v-alert
      v-if="usingMockData"
      type="warning"
      variant="tonal"
      class="mb-4"
      icon="mdi-database-off"
      closable
    >
      <strong>Using Local Mock Data:</strong> Connection to server failed. Showing offline data.
    </v-alert>

    <v-row>
      <v-col cols="12">
        <v-carousel
          cycle
          height="400"
          hide-delimiter-background
          show-arrows="hover"
        >
          <v-carousel-item
            v-for="(slide, i) in slides"
            :key="i"
            :src="slide.src"
            cover
          >
            <v-sheet
              height="100%"
              color="rgba(0, 0, 0, 0.5)"
              class="d-flex align-center justify-center"
            >
              <div class="text-center">
                <h1 class="text-h3 font-weight-bold white--text">{{ slide.title }}</h1>
                <div class="text-h6 white--text mb-4">{{ slide.subtitle }}</div>
                <v-btn color="primary" to="/products">Shop Now</v-btn>
              </div>
            </v-sheet>
          </v-carousel-item>
        </v-carousel>
      </v-col>
    </v-row>

    <v-row class="mt-8">
      <h2 class="text-h4 text-center mb-6">Featured Products</h2>
      <v-row>
        <v-col
          v-for="product in featuredProducts"
          :key="product.id"
          cols="12"
          sm="6"
          md="4"
        >
          <v-card
            class="mx-auto"
            max-width="344"
            height="100%"
            :to="`/products/${product.id}`"
          >
            <v-img
              :src="product.image"
              height="200px"
              cover
            ></v-img>
            <v-card-title>{{ product.name }}</v-card-title>
            <v-card-subtitle>${{ product.price.toFixed(2) }}</v-card-subtitle>
            <v-card-actions>
              <v-btn
                color="primary"
                variant="text"
                :to="`/products/${product.id}`"
              >
                View Product
              </v-btn>
              <v-spacer></v-spacer>
              <v-btn
                icon
                @click.prevent="addToCart(product)"
              >
                <v-icon>mdi-cart-plus</v-icon>
              </v-btn>
            </v-card-actions>
          </v-card>
        </v-col>
      </v-row>
    </v-row>
  </v-container>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useProductStore } from '@/stores/products';
import type { Product } from '@/types';

export default defineComponent({
  name: 'HomePage',
  setup() {
    const productStore = useProductStore();
    
    // Fetch products when component is set up
    productStore.fetchProducts(); 

    // Use a computed property for featuredProducts to react to store changes
    const featuredProducts = computed(() => 
      productStore.allProducts.filter(p => p.featured)
    );
    
    return { 
      featuredProducts,
      slides: [
        {
          src: 'https://via.placeholder.com/1200x400?text=Great+Deals',
          title: 'Welcome to InsecurAzon',
          subtitle: 'Find amazing deals on electronics, clothing, and more!'
        },
        {
          src: 'https://via.placeholder.com/1200x400?text=New+Arrivals',
          title: 'New Arrivals',
          subtitle: 'Check out our latest products'
        },
        {
          src: 'https://via.placeholder.com/1200x400?text=Special+Offers',
          title: 'Special Offers',
          subtitle: 'Limited time discounts on popular items'
        }
      ],
      // Expose loading and error for template use if needed
      loading: computed(() => productStore.loading),
      error: computed(() => productStore.error),
      usingMockData: computed(() => productStore.usingMockData)
    };
  },
  methods: {
    addToCart(product: Product) {
      console.log('Adding to cart:', product);
      alert(`Added ${product.name} to cart`);
    }
  }
});
</script> 