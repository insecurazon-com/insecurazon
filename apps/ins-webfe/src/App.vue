<script>
export default {
  name: 'App',
  data() {
    return {
      drawer: false,
      cartItemCount: 0,
      menuItems: [
        { title: 'Home', path: '/', icon: 'mdi-home' },
        { title: 'Products', path: '/products', icon: 'mdi-shopping' },
        { title: 'Cart', path: '/cart', icon: 'mdi-cart' },
        { title: 'Checkout', path: '/checkout', icon: 'mdi-cash-register' }
      ]
    }
  }
}
</script>

<template>
  <v-app>
    <v-app-bar app color="primary" dark>
      <v-app-bar-nav-icon @click="drawer = !drawer"></v-app-bar-nav-icon>
      <v-toolbar-title>
        <router-link to="/" style="text-decoration: none; color: inherit;">
          InsecurAzon
        </router-link>
      </v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn icon to="/cart">
        <v-badge :content="cartItemCount" :value="cartItemCount" color="error">
          <v-icon>mdi-cart</v-icon>
        </v-badge>
      </v-btn>
    </v-app-bar>

    <v-navigation-drawer v-model="drawer" temporary app>
      <v-list-item>
        <v-list-item-title class="text-h6">
          InsecurAzon
        </v-list-item-title>
        <v-list-item-subtitle>
          E-Commerce Demo
        </v-list-item-subtitle>
      </v-list-item>

      <v-divider></v-divider>

      <v-list dense nav>
        <v-list-item 
          v-for="item in menuItems" 
          :key="item.title" 
          :to="item.path" 
          link
        >
          <template v-slot:prepend>
            <v-icon>{{ item.icon }}</v-icon>
          </template>
          
          <v-list-item-title>{{ item.title }}</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-navigation-drawer>

    <v-main style="width: 100vw !important; max-width: 100vw">
      <v-container fluid>
        <router-view />
      </v-container>
    </v-main>

    <v-footer app padless color="primary" dark>
      <v-col class="text-center" cols="12">
        {{ new Date().getFullYear() }} — <strong>InsecurAzon Demo</strong>
      </v-col>
    </v-footer>
  </v-app>
</template>

<style scoped>
header {
  line-height: 1.5;
}

.logo {
  display: block;
  margin: 0 auto 2rem;
}

@media (min-width: 1024px) {
  header {
    display: flex;
    place-items: center;
    padding-right: calc(var(--section-gap) / 2);
  }

  .logo {
    margin: 0 2rem 0 0;
  }

  header .wrapper {
    display: flex;
    place-items: flex-start;
    flex-wrap: wrap;
  }
}
</style>
