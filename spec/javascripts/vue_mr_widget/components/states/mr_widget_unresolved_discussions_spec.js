import Vue from 'vue';
import unresolvedDiscussionsComponent from '~/vue_merge_request_widget/components/states/mr_widget_unresolved_discussions.vue';
import mountComponent from '../../../helpers/vue_mount_component_helper';

describe('MRWidgetUnresolvedDiscussions', () => {
  const Component = Vue.extend(unresolvedDiscussionsComponent);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('with discussions path', () => {
    it('should have correct elements', () => {
      vm = mountComponent(Component, { mr: {
        createIssueToResolveDiscussionsPath: 'foo/bar',
      } });
      expect(vm.$el.innerText).toContain('There are unresolved discussions. Please resolve these discussions');
      expect(vm.$el.innerText).toContain('Create an issue to resolve them later');
      expect(vm.$el.querySelector('.js-create-issue').getAttribute('href')).toEqual('foo/bar');
    });
  });

  describe('without discussions path', () => {
    it('should not show create issue link if user cannot create issue', () => {
      vm = mountComponent(Component, { mr: {
        createIssueToResolveDiscussionsPath: '',
      } });
      expect(vm.$el.innerText).toContain('There are unresolved discussions. Please resolve these discussions');
      expect(vm.$el.innerText).toContain('Create an issue to resolve them later');
      expect(vm.$el.querySelector('.js-create-issue')).toEqual(null);
    });
  });
});
