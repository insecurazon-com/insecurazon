<template>
  <div>
    <v-container v-if="product">
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

      <v-breadcrumbs :items="breadcrumbs"></v-breadcrumbs>
      
      <v-row>
        <v-col cols="12" md="6">
          <v-img
            :src="product.image"
            height="400"
            contain
            class="bg-grey-lighten-2"
          ></v-img>
        </v-col>
        
        <v-col cols="12" md="6">
          <h1 class="text-h4 mb-2">{{ product.name }}</h1>
          <div class="d-flex align-center mb-4">
            <v-rating
              :model-value="product.rating || 0"
              color="amber"
              density="compact"
              half-increments
              readonly
              size="small"
            ></v-rating>
            <span class="text-body-2 ml-2">({{ product.reviewCount || 0 }} reviews)</span>
          </div>
          
          <v-divider class="mb-4"></v-divider>
          
          <div class="text-h5 mb-4">${{ product.price.toFixed(2) }}</div>
          
          <p class="text-body-1 mb-6">{{ product.description }}</p>
          
          <div class="d-flex align-center mb-6">
            <v-select
              v-model="quantity"
              :items="Array.from({length: 10}, (_, i) => i + 1)"
              label="Quantity"
              hide-details
              class="mr-4"
              style="max-width: 100px"
            ></v-select>
            
            <v-btn
              color="primary"
              size="large"
              @click="addToCart"
            >
              <v-icon left>mdi-cart</v-icon>
              Add to Cart
            </v-btn>
          </div>
          
          <v-alert
            type="info"
            variant="tonal"
            icon="mdi-truck-delivery"
          >
            Free shipping on orders over $50
          </v-alert>
        </v-col>
      </v-row>
      
      <v-divider class="my-8"></v-divider>
      
      <v-row>
        <v-col cols="12">
          <h2 class="text-h5 mb-4">Product Details</h2>
          
          <v-tabs v-model="tab">
            <v-tab value="description">Description</v-tab>
            <v-tab value="specifications">Specifications</v-tab>
            <v-tab value="reviews">Reviews</v-tab>
          </v-tabs>
          
          <v-window v-model="tab" class="mt-4">
            <v-window-item value="description">
              <v-card flat>
                <v-card-text>
                  <p>{{ product.fullDescription || product.description }}</p>
                </v-card-text>
              </v-card>
            </v-window-item>
            
            <v-window-item value="specifications">
              <v-card flat>
                <v-card-text>
                  <v-list lines="two" v-if="product.specifications">
                    <v-list-item v-for="(spec, key) in product.specifications" :key="key">
                      <template v-slot:prepend>
                        <span class="font-weight-bold">{{ key }}:</span>
                      </template>
                      <v-list-item-title>{{ spec }}</v-list-item-title>
                    </v-list-item>
                  </v-list>
                  <p v-else>No specifications available.</p>
                </v-card-text>
              </v-card>
            </v-window-item>
            
            <v-window-item value="reviews">
              <v-card flat>
                <v-card-text>
                  <div v-if="product.reviews && product.reviews.length > 0">
                    <v-list>
                      <v-list-item v-for="(review, index) in product.reviews" :key="index">
                        <template v-slot:prepend>
                          <v-avatar color="primary" class="mr-3">
                            <span class="text-h6 white--text">{{ review.userName.charAt(0) }}</span>
                          </v-avatar>
                        </template>
                        <v-list-item-title class="font-weight-bold">{{ review.userName }}</v-list-item-title>
                        <v-list-item-subtitle>
                          <v-rating
                            :model-value="review.rating"
                            color="amber"
                            density="compact"
                            size="x-small"
                            readonly
                          ></v-rating>
                        </v-list-item-subtitle>
                        <v-list-item-text>{{ review.comment }}</v-list-item-text>
                      </v-list-item>
                    </v-list>
                  </div>
                  <div v-else class="text-center py-4">
                    <p>No reviews yet</p>
                  </div>
                </v-card-text>
              </v-card>
            </v-window-item>
          </v-window>
        </v-col>
      </v-row>
    </v-container>
    
    <v-container v-else>
      <v-row>
        <v-col cols="12" class="text-center">
          <v-progress-circular
            v-if="loading"
            indeterminate
            color="primary"
            size="64"
          ></v-progress-circular>
          <v-alert
            v-else
            type="error"
            variant="text"
          >
            Product not found!
          </v-alert>
          <div class="mt-4">
            <v-btn color="primary" to="/products">
              Back to Products
            </v-btn>
          </div>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import { useProductStore } from '@/stores/products';
import type { Product } from '@/types';
import { mapState } from 'pinia';

export default defineComponent({
  name: 'ProductDetailPage',
  setup() {
    const productStore = useProductStore();
    productStore.fetchProducts();
    return { productStore };
  },
  data() {
    return {
      loading: true,
      quantity: 1,
      tab: 'description',
      product: null as Product | null,
    };
  },
  computed: {
    ...mapState(useProductStore, ['getProductById']),
    storeLoading() {
      return this.productStore.loading;
    },
    storeError() {
      return this.productStore.error;
    },
    breadcrumbs() {
      return [
        {
          title: 'Home',
          disabled: false,
          href: '/'
        },
        {
          title: 'Products',
          disabled: false,
          href: '/products'
        },
        {
          title: this.product ? this.product.name : 'Product Detail',
          disabled: true
        }
      ];
    }
  },
  methods: {
    addToCart() {
      if (this.product) {
        console.log(`Adding ${this.quantity} of ${this.product.name} to cart`);
        alert(`Added ${this.quantity} of ${this.product.name} to cart`);
      }
    },
    loadProduct() {
      const routeId = this.$route.params.id;
      const productId = parseInt(Array.isArray(routeId) ? routeId[0] : routeId, 10);

      if (!isNaN(productId)) {
        const foundProduct: Product | undefined = this.productStore.getProductById(productId);
        if (foundProduct) {
          this.product = foundProduct;
        } else {
          this.product = null;
          if (!this.productStore.loading) {
             console.error(`Product with id ${productId} not found after store load.`);
          }
        }
      } else {
        this.product = null;
        console.error('Invalid product ID in route.');
      }
    }
  },
  created() {
    this.productStore.fetchProducts().then(() => {
      this.loadProduct();
      this.loading = this.productStore.loading;
    });
  },
  watch: {
    '$route.params.id': {
      handler() {
        this.productStore.fetchProducts().then(() => {
            this.loadProduct();
            this.loading = this.productStore.loading;
        });
      },
    },
    storeLoading(newVal) {
      this.loading = newVal;
      if (!newVal && !this.product) {
        this.loadProduct();
      }
    }
  }
});
</script> 