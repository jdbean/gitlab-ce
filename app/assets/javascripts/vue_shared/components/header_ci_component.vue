<script>
import CiIconBadge from './ci_badge_link.vue';
import TimeagoTooltip from './time_ago_tooltip.vue';
import tooltip from '../directives/tooltip';
import UserAvatarImage from './user_avatar/user_avatar_image.vue';

/**
 * Renders header component for job and pipeline page based on UI mockups
 *
 * Used in:
 * - job show page
 * - pipeline show page
 */
export default {
  components: {
    CiIconBadge,
    TimeagoTooltip,
    UserAvatarImage,
  },
  directives: {
    tooltip,
  },
  props: {
    status: {
      type: Object,
      required: true,
    },
    itemName: {
      type: String,
      required: true,
    },
    itemId: {
      type: Number,
      required: true,
    },
    time: {
      type: String,
      required: true,
    },
    user: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    actions: {
      type: Array,
      required: false,
      default: () => [],
    },
    hasSidebarButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    shouldRenderTriggeredLabel: {
      type: Boolean,
      required: false,
      default: true,
    },
  },

  computed: {
    userAvatarAltText() {
      return `${this.user.name}'s avatar`;
    },
  },

  methods: {
    onClickAction(action) {
      this.$emit('actionClicked', action);
    },
    onClickSidebarButton() {
      this.$emit('clickedSidebarButton');
    },
  },
};
</script>

<template>
  <header class="page-content-header ci-header-container">
    <section class="header-main-content">

      <ci-icon-badge :status="status" />

      <strong>
        {{ itemName }} #{{ itemId }}
      </strong>

      <template v-if="shouldRenderTriggeredLabel">
        triggered
      </template>
      <template v-else>
        created
      </template>

      <timeago-tooltip :time="time" />

      by

      <template v-if="user">
        <a
          v-tooltip
          :href="user.path"
          :title="user.email"
          class="js-user-link commit-committer-link"
        >

          <user-avatar-image
            :img-src="user.avatar_url"
            :img-alt="userAvatarAltText"
            :tooltip-text="user.name"
            :img-size="24"
          />

          {{ user.name }}
        </a>
        <span
          v-if="user.status_tooltip_html"
          v-html="user.status_tooltip_html"></span>
      </template>
    </section>

    <section
      v-if="actions.length"
      class="header-action-buttons"
    >
      <template
        v-for="(action, i) in actions"
      >
        <a
          v-if="action.type === 'link'"
          :key="i"
          :href="action.path"
          :class="action.cssClass"
        >
          {{ action.label }}
        </a>

        <a
          v-else-if="action.type === 'ujs-link'"
          :key="i"
          :href="action.path"
          :class="action.cssClass"
          data-method="post"
          rel="nofollow"
        >
          {{ action.label }}
        </a>

        <button
          v-else-if="action.type === 'button'"
          :key="i"
          :disabled="action.isLoading"
          :class="action.cssClass"
          type="button"
          @click="onClickAction(action)"
        >
          {{ action.label }}
          <i
            v-show="action.isLoading"
            class="fa fa-spin fa-spinner"
            aria-hidden="true"
          >
          </i>
        </button>
      </template>
    </section>
    <button
      v-if="hasSidebarButton"
      id="toggleSidebar"
      type="button"
      class="btn btn-default d-block d-sm-none
sidebar-toggle-btn js-sidebar-build-toggle js-sidebar-build-toggle-header"
      @click="onClickSidebarButton"
    >
      <i
        class="fa fa-angle-double-left"
        aria-hidden="true"
        aria-labelledby="toggleSidebar"
      >
      </i>
    </button>
  </header>
</template>
