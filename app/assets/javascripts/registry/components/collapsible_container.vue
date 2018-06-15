<script>
  import { mapActions } from 'vuex';
  import ClipboardButton from '../../vue_shared/components/clipboard_button.vue';
  import LoadingIcon from '../../vue_shared/components/loading_icon.vue';
  import TableRegistry from './table_registry.vue';
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    name: 'CollapsibeContainerRegisty',
    components: {
      ClipboardButton,
      LoadingIcon,
      TableRegistry,
    },
    directives: {
      tooltip,
    },
    props: {
      repo: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        isOpen: false,
      };
    },
    methods: {
      ...mapActions(['fetchRepos', 'fetchList', 'deleteRepo']),

      toggleRepo() {
        this.isOpen = !this.isOpen;

        if (this.isOpen) {
          this.fetchList({ repo: this.repo });
        }
      },

      handleDeleteRepository() {
        this.deleteRepo(this.repo);
      },
    },
  };
</script>

<template>
  <div class="container-image">
    <div class="container-image-head">
      <button
        type="button"
        class="js-toggle-repo btn-link"
        @click="toggleRepo"
      >
        <i
          :class="{
            'fa-chevron-right': !isOpen,
            'fa-chevron-up': isOpen,
          }"
          class="fa"
          aria-hidden="true"
        >
        </i>
        {{ repo.name }}
      </button>

      <clipboard-button
        v-if="repo.location"
        :text="repo.location"
        :title="repo.location"
        css-class="btn-default btn-transparent btn-clipboard"
      />

      <div class="controls d-none d-sm-block float-right">
        <button
          v-tooltip
          v-if="repo.canDelete"
          :title="s__('ContainerRegistry|Remove repository')"
          :aria-label="s__('ContainerRegistry|Remove repository')"
          type="button"
          class="js-remove-repo btn btn-danger"
          @click="handleDeleteRepository"
        >
          <i
            class="fa fa-trash"
            aria-hidden="true"
          >
          </i>
        </button>
      </div>
    </div>

    <loading-icon
      v-if="repo.isLoading"
      class="append-bottom-20"
      size="2"
    />

    <div
      v-else-if="!repo.isLoading && isOpen"
      class="container-image-tags"
    >

      <table-registry
        v-if="repo.list.length"
        :repo="repo"
      />

      <div
        v-else
        class="nothing-here-block"
      >
        {{ s__("ContainerRegistry|No tags in Container Registry for this container image.") }}
      </div>
    </div>
  </div>
</template>
