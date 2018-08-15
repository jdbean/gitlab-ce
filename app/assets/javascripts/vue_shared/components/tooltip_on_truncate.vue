<script>
import tooltip from '../directives/tooltip';

export default {
  directives: {
    tooltip,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    placement: {
      type: String,
      required: false,
      default: 'top',
    },
    truncateTarget: {
      type: [String, Function],
      required: false,
      default: '',
    },
  },
  data() {
    return {
      showTooltip: false,
    };
  },
  mounted() {
    const target = this.selectTarget();

    if (target && target.scrollWidth > target.offsetWidth) {
      this.showTooltip = true;
    }
  },
  methods: {
    selectTarget() {
      const targetFn = this.truncateTarget;

      if (!targetFn) {
        return this.$el;
      } else if (targetFn.apply) {
        return targetFn(this.$el);
      } else if (targetFn === 'child') {
        return this.$el.childNodes[0];
      }

      return this.$el;
    },
  },
};
</script>

<template>
  <span
    v-tooltip
    v-if="showTooltip"
    :title="title"
    :data-placement="placement"
    class="js-show-tooltip"
  >
    <slot></slot>
  </span>
  <span
    v-else
  >
    <slot></slot>
  </span>
</template>
