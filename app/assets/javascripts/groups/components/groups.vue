<script>
  import bp from '../../breakpoints';
  import { mergeUrlParams } from '~/lib/utils/url_utility';
  import { s__ } from '../../locale';

  export default {
    props: {
      groups: {
        type: Array,
        required: true,
      },
      pageInfo: {
        type: Object,
        required: true,
      },
      searchEmpty: {
        type: Boolean,
        required: true,
      },
      searchEmptyMessage: {
        type: String,
        required: true,
      },
    },
    data: () => ({
      breakpoint: bp.getBreakpointSize()
    }),
    created () {
      window.addEventListener('resize', this.setBreakpoint)
    },
    beforeDestroy () {
      window.removeEventListener('resize', this.setBreakpoint)
    },
    computed: {
      paginationLimit () {
        switch (this.breakpoint) {
          case 'xs':
            return 1
          case 'sm':
            return 5
          default:
            return 11
        }
      }
    },
    methods: {
      change(page) {
        return mergeUrlParams({ page }, window.location.href);
      },
      setBreakpoint () {
        this.breakpoint = bp.getBreakpointSize()
      }
    }
  };
</script>

<template>
  <div class="groups-list-tree-container">
    <div
      v-if="searchEmpty"
      class="has-no-search-results"
    >
      {{ searchEmptyMessage }}
    </div>
    <group-folder
      v-if="!searchEmpty"
      :groups="groups"
    />
    <gl-pagination
      class="gl-pagination d-flex justify-content-center prepend-top-default"
      v-if="!searchEmpty && pageInfo.totalPages > 1"
      :limit="paginationLimit"
      :link-gen="change"
      :value="pageInfo.page"
      :number-of-pages="pageInfo.totalPages"
      :first-text="s__('Pagination|« First')"
      :prev-text="s__('Pagination|Prev')"
      :next-text="s__('Pagination|Next')"
      :last-text="s__('Pagination|Last »')"
    />
  </div>
</template>
