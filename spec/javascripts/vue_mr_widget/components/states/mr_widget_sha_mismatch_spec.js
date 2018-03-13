import Vue from 'vue';
import shaMismatchComponent from '~/vue_merge_request_widget/components/states/mr_widget_sha_mismatch.vue';
import mountComponet from '../../../helpers/vue_mount_component_helper';

describe('MRWidgetSHAMismatch', () => {
  const Component = Vue.extend(shaMismatchComponent);
  const vm = mountComponet(Component);

  afterEach(() => {
    vm.$destroy();
  });

  it('should render information message', () => {
    expect(vm.$el.querySelector('button').disabled).toEqual(true);

    expect(
      vm.$el.textContent.replace(/\r?\n|\r/g, ' ').trim(),
    ).toContain('The source branch HEAD has recently changed. Please reload the page and review the changes before merging');
  });
});
