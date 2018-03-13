<script>
  import StatusIcon from '../mr_widget_status_icon.vue';

  export default {
    name: 'MRWidgetUnresolvedDiscussions',
    components: {
      StatusIcon,
    },
    props: {
      // TODO: Change the way we do this.
      // We need exactly 1 string but we are providing an entire store down :(
      mr: {
        type: Object,
        required: true,
      },
    },
  };
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon
      status="warning"
      :show-disabled-button="true"
    />
    <div class="media-body space-children">
      <span class="bold">
        {{ s__("mrWidget|There are unresolved discussions. Please resolve these discussions") }}
      </span>
      <a
        v-if="mr.createIssueToResolveDiscussionsPath"
        :href="mr.createIssueToResolveDiscussionsPath"
        class="btn btn-default btn-xs js-create-issue"
      >
        {{ s__("mrWidget|Create an issue to resolve them later") }}
      </a>
    </div>
  </div>
</template>

