<script>
  import { mapGetters, mapActions } from 'vuex';
  import store from '../store';
  import LoadingIcon from '../../vue_shared/components/loading_icon.vue';
  import CollapsibleContainer from './collapsible_container.vue';

  export default {
    name: 'RegistryListApp',
    components: {
      CollapsibleContainer,
      LoadingIcon,
    },
    props: {
      endpoint: {
        type: String,
        required: true,
      },
    },
    store,
    computed: {
      ...mapGetters(['isLoading', 'repos']),
    },
    created() {
      this.setMainEndpoint(this.endpoint);
    },
    mounted() {
      this.fetchRepos();
    },
    methods: {
      ...mapActions(['setMainEndpoint', 'fetchRepos']),
    },
  };
</script>
<template>
  <div>
    <loading-icon
      v-if="isLoading"
      size="3"
    />

    <collapsible-container
      v-for="(item, index) in repos"
      v-else-if="!isLoading && repos.length"
      :key="index"
      :repo="item"
    />

    <p v-else-if="!isLoading && !repos.length">
      {{ __(`No container images stored for this project.
Add one by following the instructions above.`) }}
    </p>
  </div>
</template>
