import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import deploymentComponent from '~/vue_merge_request_widget/components/mr_widget_deployment.vue';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('MRWidgetDeployment', () => {
  let vm;
  let Component;
  const deployments = [{
    id: 137,
    name: 'production',
    url: '/gitlab-com/www-gitlab-com/environments/137',
    metrics_url: null,
    metrics_monitoring_url: '/gitlab-com/www-gitlab-com/environments/137/metrics',
    stop_url: null,
    external_url: 'https://about.gitlab.com',
    external_url_formatted: 'about.gitlab.com',
    deployed_at: '2018-02-02T05:30:14.652Z',
    deployed_at_formatted: 'Feb 2, 2018 5:30am',
  }, {
    id: 222417,
    name: 'review/patch-796',
    url: '/gitlab-com/www-gitlab-com/environments/222417',
    metrics_url: null,
    metrics_monitoring_url: '/gitlab-com/www-gitlab-com/environments/222417/metrics',
    stop_url: '/gitlab-com/www-gitlab-com/environments/222417/stop',
    external_url: 'http://patch-796.about.gitlab.com',
    external_url_formatted: 'patch-796.about.gitlab.com',
    deployed_at: '2018-02-01T21:34:09.972Z',
    deployed_at_formatted: 'Feb 1, 2018 9:34pm',
  }];
  let mock;

  beforeEach(() => {
    Component = Vue.extend(deploymentComponent);
    mock = new MockAdapter(axios);
    mock.onPost('/gitlab-com/www-gitlab-com/environments/222417/stop').reply(200, {
      redirect_url: '',
    }, {});

    vm = mountComponent(Component, { deployments });
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();
  });

  describe('methods', () => {
    describe('hasExternalUrls', () => {
      it('returns true when both keys are present', () => {
        expect(vm.hasExternalUrls(deployments[0])).toEqual(true);
      });

      it('should return false when there is not enough information', () => {
        expect(vm.hasExternalUrls()).toEqual(false);
        expect(vm.hasExternalUrls({ external_url: '' })).toEqual(false);
        expect(vm.hasExternalUrls({ external_url_formatted: '' })).toEqual(false);
      });
    });

    describe('hasDeploymentTime', () => {
      it('returns true when deployment time is present', () => {
        expect(vm.hasDeploymentTime(deployments[0])).toEqual(true);
      });

      it('return sfalse when there is not enough information', () => {
        expect(vm.hasDeploymentTime()).toEqual(false);
        expect(vm.hasDeploymentTime({ deployed_at: '' })).toEqual(false);
        expect(vm.hasDeploymentTime({ deployed_at_formatted: '' })).toEqual(false);
      });
    });

    describe('hasDeploymentMeta', () => {
      it('returns true wehn url and name are presnet', () => {
        expect(vm.hasDeploymentMeta(deployments[0])).toEqual(true);
      });

      it('returns false when there is not enough information', () => {
        expect(vm.hasDeploymentMeta()).toEqual(false);
        expect(vm.hasDeploymentMeta({ url: '' })).toEqual(false);
        expect(vm.hasDeploymentMeta({ name: '' })).toEqual(false);
      });
    });

    describe('stopEnvironment', () => {
      it('shows a confirm dialog', () => {
        spyOn(window, 'confirm').and.returnValue(true);

        vm.stopEnvironment(deployments[1]);
        expect(window.confirm).toHaveBeenCalled();
      });

      it('makes a request to the service when confirmation is given', (done) => {
        spyOn(window, 'confirm').and.returnValue(true);
        spyOn(MRWidgetService, 'stopEnvironment').and.callThrough();

        vm.stopEnvironment(deployments[1]);

        setTimeout(() => {
          expect(MRWidgetService.stopEnvironment).toHaveBeenCalled();
          done();
        }, 0);
      });

      it('does not make a request to the service when confirmation is not given', () => {
        spyOn(MRWidgetService, 'stopEnvironment').and.callThrough();
        spyOn(window, 'confirm').and.returnValue(false);

        vm.stopEnvironment(deployments[1]);

        expect(MRWidgetService.stopEnvironment).not.toHaveBeenCalled();
      });
    });
  });

  it('renders the given deployments', () => {
    expect(vm.$el.querySelectorAll('.js-deploy-block').length).toEqual(2);
    expect(vm.$el.textContent.trim()).toContain(deployments[0].name);
    expect(vm.$el.textContent.trim()).toContain(deployments[1].name);
  });

  it('renders stop button when stop url is provided', () => {
    expect(
      vm.$el.querySelector('.js-deploy-block:nth-child(2) .js-stop-environment').textContent.trim(),
    ).toEqual('Stop environment');
    expect(vm.$el.querySelector('.js-deploy-block:nth-child(1) .js-stop-environment')).toEqual(null);
  });

  it('renders deployment information', () => {
    expect(vm.$el.querySelector('.js-deploy-block').textContent.trim()).toContain('Deployed to');
    expect(vm.$el.querySelector('.js-deploy-block').textContent.trim()).toContain(deployments[0].external_url_formatted);
  });
});
