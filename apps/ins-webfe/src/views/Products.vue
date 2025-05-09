<template>
  <div>
    <v-container>
      <!-- Mock Data Alert Banner -->
      <v-alert
        v-if="productStore.usingMockData"
        type="warning"
        variant="tonal"
        class="mb-4"
        icon="mdi-database-off"
        closable
      >
        <strong>Using Local Mock Data:</strong> Connection to server failed. Showing offline data.
      </v-alert>

      <h1 class="text-h4 mb-6">Products</h1>
      
      <v-row>
        <!-- Filters -->
        <v-col cols="12" md="3">
          <v-card>
            <v-card-title>Filters</v-card-title>
            <v-card-text>
              <h3 class="text-subtitle-1 mb-2">Categories</h3>
              <v-checkbox
                v-for="category in categories"
                :key="category.id"
                v-model="selectedCategories"
                :label="category.name"
                :value="category.id"
                hide-details
                dense
              ></v-checkbox>
              
              <v-divider class="my-4"></v-divider>
              
              <h3 class="text-subtitle-1 mb-2">Price Range</h3>
              <v-range-slider
                v-model="priceRange"
                :min="0"
                :max="1000"
                :step="10"
                thumb-label="always"
                class="mt-6"
              >
                <template v-slot:prepend>
                  <span class="mt-4">${{ priceRange[0] }}</span>
                </template>
                <template v-slot:append>
                  <span class="mt-4">${{ priceRange[1] }}</span>
                </template>
              </v-range-slider>
              
              <v-btn 
                color="primary" 
                block 
                class="mt-4"
                @click="applyFilters"
              >
                Apply Filters
              </v-btn>
            </v-card-text>
          </v-card>
        </v-col>
        
        <!-- Products Grid -->
        <v-col cols="12" md="9">
          <v-row>
            <v-col cols="12">
              <v-text-field
                v-model="searchQuery"
                label="Search products"
                prepend-inner-icon="mdi-magnify"
                outlined
                dense
                clearable
                @input="searchProducts"
              ></v-text-field>
            </v-col>
          </v-row>
          
          <v-row v-if="filteredProducts.length > 0">
            <v-col
              v-for="product in filteredProducts"
              :key="product.id"
              cols="12"
              sm="6"
              md="4"
            >
              <v-card
                class="mx-auto mb-6"
                height="100%"
              >
                <v-img
                  :src="product.image"
                  height="200px"
                  cover
                ></v-img>
                <v-card-title>{{ product.name }}</v-card-title>
                <v-card-subtitle>${{ product.price.toFixed(2) }}</v-card-subtitle>
                <v-card-text>
                  <div class="text-truncate">{{ product.description }}</div>
                </v-card-text>
                <v-card-actions>
                  <v-btn
                    color="primary"
                    variant="text"
                    :to="`/products/${product.id}`"
                  >
                    View Details
                  </v-btn>
                  <v-spacer></v-spacer>
                  <v-btn
                    icon
                    @click="addToCart(product)"
                  >
                    <v-icon>mdi-cart-plus</v-icon>
                  </v-btn>
                </v-card-actions>
              </v-card>
            </v-col>
          </v-row>
          
          <v-row v-else>
            <v-col cols="12" class="text-center">
              <v-alert
                type="info"
                variant="text"
              >
                No products found matching your criteria.
              </v-alert>
            </v-col>
          </v-row>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import { useProductStore } from '@/stores/products';
import { mapState } from 'pinia';
import type { Product, Category } from '@/types'; // Import types

export default defineComponent({
  name: 'ProductsPage',
  setup() {
    const productStore = useProductStore();
    // Fetch data when component is set up
    productStore.fetchProducts();
    productStore.fetchCategories();
    return { productStore }; 
  },
  data() {
    return {
      searchQuery: '',
      selectedCategories: [] as number[], // Typed selectedCategories
      priceRange: [0, 1000] as [number, number],
      filteredProducts: [] as Product[], // Typed filteredProducts
    };
  },
  computed: {
    // Use the store's loading and error states in the template if desired
    loading() {
      return this.productStore.loading;
    },
    error() {
      return this.productStore.error;
    },
    // products and categories are already mapped from store getters
    ...mapState(useProductStore, {
      products: 'allProducts',
      categories: 'allCategories',
    }),
  },
  methods: {
    searchProducts() {
      this.applyFilters();
    },
    applyFilters() {
      let tempProducts = this.productStore.allProducts;

      if (this.searchQuery) {
        const lowerSearchQuery = this.searchQuery.toLowerCase();
        tempProducts = tempProducts.filter(product =>
          product.name.toLowerCase().includes(lowerSearchQuery) ||
          product.description.toLowerCase().includes(lowerSearchQuery)
        );
      }

      if (this.selectedCategories.length > 0) {
        tempProducts = tempProducts.filter(product =>
          this.selectedCategories.includes(product.categoryId)
        );
      }

      tempProducts = tempProducts.filter(product =>
        product.price >= this.priceRange[0] && product.price <= this.priceRange[1]
      );

      this.filteredProducts = tempProducts;

      // Fallback to show all products if filters result in an empty list but no specific filters were applied
      if (this.filteredProducts.length === 0 && this.searchQuery === '' && this.selectedCategories.length === 0 && this.priceRange[0] === 0 && this.priceRange[1] === 1000) {
        this.filteredProducts = [...this.productStore.allProducts];
      }
    },
    addToCart(product: Product) { // Typed product parameter
      console.log('Adding to cart:', product);
      alert(`Added ${product.name} to cart`);
    }
  }
});
</script> 