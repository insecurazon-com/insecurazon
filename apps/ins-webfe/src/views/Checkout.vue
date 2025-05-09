<template>
  <div>
    <v-container>
      <h1 class="text-h4 mb-6">Checkout</h1>
      
      <v-stepper v-model="currentStep">
        <v-stepper-header>
          <v-stepper-item value="1">Shipping</v-stepper-item>
          <v-divider></v-divider>
          <v-stepper-item value="2">Payment</v-stepper-item>
          <v-divider></v-divider>
          <v-stepper-item value="3">Review</v-stepper-item>
        </v-stepper-header>

        <v-stepper-window>
          <!-- Step 1: Shipping Information -->
          <v-stepper-window-item value="1">
            <v-card class="mb-4">
              <v-card-title>Shipping Information</v-card-title>
              <v-card-text>
                <v-form ref="shippingForm" v-model="shippingFormValid">
                  <v-row>
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model="shipping.firstName"
                        label="First Name"
                        required
                        :rules="[v => !!v || 'First name is required']"
                      ></v-text-field>
                    </v-col>
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model="shipping.lastName"
                        label="Last Name"
                        required
                        :rules="[v => !!v || 'Last name is required']"
                      ></v-text-field>
                    </v-col>
                  </v-row>
                  
                  <v-text-field
                    v-model="shipping.email"
                    label="Email Address"
                    type="email"
                    required
                    :rules="[
                      v => !!v || 'Email is required',
                      v => /.+@.+\..+/.test(v) || 'Email must be valid'
                    ]"
                  ></v-text-field>
                  
                  <v-text-field
                    v-model="shipping.phone"
                    label="Phone Number"
                    required
                    :rules="[v => !!v || 'Phone number is required']"
                  ></v-text-field>
                  
                  <v-text-field
                    v-model="shipping.address"
                    label="Address"
                    required
                    :rules="[v => !!v || 'Address is required']"
                  ></v-text-field>
                  
                  <v-row>
                    <v-col cols="12" md="4">
                      <v-text-field
                        v-model="shipping.city"
                        label="City"
                        required
                        :rules="[v => !!v || 'City is required']"
                      ></v-text-field>
                    </v-col>
                    <v-col cols="12" md="4">
                      <v-select
                        v-model="shipping.state"
                        :items="states"
                        label="State"
                        required
                        :rules="[v => !!v || 'State is required']"
                      ></v-select>
                    </v-col>
                    <v-col cols="12" md="4">
                      <v-text-field
                        v-model="shipping.zip"
                        label="ZIP Code"
                        required
                        :rules="[v => !!v || 'ZIP code is required']"
                      ></v-text-field>
                    </v-col>
                  </v-row>
                </v-form>
              </v-card-text>
              <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn
                  color="primary"
                  @click="validateAndProceed(1)"
                >
                  Continue to Payment
                </v-btn>
              </v-card-actions>
            </v-card>
          </v-stepper-window-item>

          <!-- Step 2: Payment Method -->
          <v-stepper-window-item value="2">
            <v-card class="mb-4">
              <v-card-title>Payment Method</v-card-title>
              <v-card-text>
                <v-form ref="paymentForm" v-model="paymentFormValid">
                  <v-radio-group v-model="payment.method" required>
                    <v-radio value="creditCard" label="Credit Card"></v-radio>
                    <v-radio value="paypal" label="PayPal"></v-radio>
                  </v-radio-group>
                  
                  <v-expand-transition>
                    <div v-if="payment.method === 'creditCard'">
                      <v-text-field
                        v-model="payment.cardName"
                        label="Name on Card"
                        required
                        :rules="[v => !!v || 'Name on card is required']"
                      ></v-text-field>
                      
                      <v-text-field
                        v-model="payment.cardNumber"
                        label="Card Number"
                        required
                        :rules="[v => !!v || 'Card number is required']"
                      ></v-text-field>
                      
                      <v-row>
                        <v-col cols="6">
                          <v-text-field
                            v-model="payment.expiryDate"
                            label="Expiry Date (MM/YY)"
                            required
                            :rules="[v => !!v || 'Expiry date is required']"
                          ></v-text-field>
                        </v-col>
                        <v-col cols="6">
                          <v-text-field
                            v-model="payment.cvv"
                            label="CVV"
                            type="password"
                            required
                            :rules="[v => !!v || 'CVV is required']"
                          ></v-text-field>
                        </v-col>
                      </v-row>
                    </div>
                  </v-expand-transition>
                  
                  <v-expand-transition>
                    <div v-if="payment.method === 'paypal'">
                      <p class="text-body-1 mt-4">You will be redirected to PayPal to complete your payment.</p>
                    </div>
                  </v-expand-transition>
                </v-form>
              </v-card-text>
              <v-card-actions>
                <v-btn
                  variant="text"
                  @click="currentStep = '1'"
                >
                  Back
                </v-btn>
                <v-spacer></v-spacer>
                <v-btn
                  color="primary"
                  @click="validateAndProceed(2)"
                >
                  Review Order
                </v-btn>
              </v-card-actions>
            </v-card>
          </v-stepper-window-item>

          <!-- Step 3: Review Order -->
          <v-stepper-window-item value="3">
            <v-row>
              <v-col cols="12" md="8">
                <v-card class="mb-4">
                  <v-card-title>Review Your Order</v-card-title>
                  <v-card-text>
                    <h3 class="text-subtitle-1 mt-2 mb-1">Shipping Address</h3>
                    <p>
                      {{ shipping.firstName }} {{ shipping.lastName }}<br>
                      {{ shipping.address }}<br>
                      {{ shipping.city }}, {{ shipping.state }} {{ shipping.zip }}<br>
                      {{ shipping.email }}<br>
                      {{ shipping.phone }}
                    </p>
                    
                    <v-divider class="my-4"></v-divider>
                    
                    <h3 class="text-subtitle-1 mt-2 mb-1">Payment Method</h3>
                    <p v-if="payment.method === 'creditCard'">
                      Credit Card ending in {{ payment.cardNumber.slice(-4) }}<br>
                      Expires: {{ payment.expiryDate }}
                    </p>
                    <p v-else>PayPal</p>
                    
                    <v-divider class="my-4"></v-divider>
                    
                    <h3 class="text-subtitle-1 mt-2 mb-2">Order Items</h3>
                    <v-list dense>
                      <v-list-item v-for="(item, index) in cartItems" :key="index">
                        <template v-slot:prepend>
                          <v-avatar size="40" rounded>
                            <v-img :src="item.product.image" cover></v-img>
                          </v-avatar>
                        </template>
                        <v-list-item-title>{{ item.product.name }} x {{ item.quantity }}</v-list-item-title>
                        <v-list-item-subtitle class="text-right">${{ (item.product.price * item.quantity).toFixed(2) }}</v-list-item-subtitle>
                      </v-list-item>
                    </v-list>
                  </v-card-text>
                  <v-card-actions>
                    <v-btn
                      variant="text"
                      @click="currentStep = '2'"
                    >
                      Back
                    </v-btn>
                    <v-spacer></v-spacer>
                    <v-btn
                      color="primary"
                      @click="placeOrder"
                      :loading="processing"
                    >
                      Place Order
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
                      <span>{{ shipping.cost > 0 ? '$' + shipping.cost.toFixed(2) : 'FREE' }}</span>
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
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
          </v-stepper-window-item>
        </v-stepper-window>
      </v-stepper>
    </v-container>
    
    <!-- Order Confirmation Dialog -->
    <v-dialog v-model="orderPlaced" max-width="500">
      <v-card>
        <v-card-title class="text-h5 text-center">
          <v-icon color="success" size="x-large" class="mr-2">mdi-check-circle</v-icon>
          Order Placed Successfully
        </v-card-title>
        <v-card-text class="text-center">
          <p class="text-body-1 mt-4">Thank you for your order!</p>
          <p class="text-body-1">Your order number is <strong>{{ orderNumber }}</strong>.</p>
          <p class="text-body-1 mb-4">A confirmation email has been sent to <strong>{{ shipping.email }}</strong>.</p>
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            to="/"
            block
          >
            Continue Shopping
          </v-btn>
          <v-spacer></v-spacer>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script lang="ts">
export default {
  name: 'CheckoutPage',
  data() {
    return {
      currentStep: '1',
      shippingFormValid: false,
      paymentFormValid: false,
      processing: false,
      orderPlaced: false,
      orderNumber: '',
      
      shipping: {
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        address: '',
        city: '',
        state: '',
        zip: '',
        cost: 0
      },
      
      payment: {
        method: 'creditCard',
        cardName: '',
        cardNumber: '',
        expiryDate: '',
        cvv: ''
      },
      
      states: [
        'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware',
        'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky',
        'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi',
        'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico',
        'New York', 'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania',
        'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
        'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'
      ],
      
      // Mock cart data - in a real app, this would be fetched from a store or API
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
    tax() {
      return this.subtotal * 0.08; // 8% tax rate
    },
    total() {
      return this.subtotal + this.shipping.cost + this.tax;
    }
  },
  methods: {
    validateAndProceed(step: number) {
      if (step === 1) {
        if (this.$refs.shippingForm && (this.$refs.shippingForm as any).validate()) {
          // Calculate shipping cost - free for orders over $50
          this.shipping.cost = this.subtotal >= 50 ? 0 : 5.99;
          this.currentStep = '2';
        }
      } else if (step === 2) {
        if (this.$refs.paymentForm && (this.$refs.paymentForm as any).validate()) {
          this.currentStep = '3';
        }
      }
    },
    placeOrder() {
      this.processing = true;
      
      // Simulate API call with timeout
      setTimeout(() => {
        // Generate a random order number
        this.orderNumber = 'INS-' + Math.floor(100000 + Math.random() * 900000);
        this.processing = false;
        this.orderPlaced = true;
        
        // In a real app, we would clear the cart here and navigate back to the home page after a delay
      }, 2000);
    }
  }
}
</script> 