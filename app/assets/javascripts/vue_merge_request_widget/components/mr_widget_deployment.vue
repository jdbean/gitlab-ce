<script>
  import { getTimeago } from '~/lib/utils/datetime_utility';
  import { visitUrl } from '~/lib/utils/url_utility';
  import Flash from '~/flash';
  import { s__ } from '~/locale';
  import tooltip from '~/vue_shared/directives/tooltip';
  import memoryUsage from './mr_widget_memory_usage';
  import statusIcon from './mr_widget_status_icon.vue';
  import MRWidgetService from '../services/mr_widget_service';

  export default {
    name: 'MRWidgetDeployment',
    directives: {
      tooltip,
    },
    components: {
      memoryUsage,
      statusIcon,
    },
    props: {
      deployments: {
        type: Array,
        required: true,
      },
    },
    methods: {
      formatDate(date) {
        return getTimeago().format(date);
      },
      hasExternalUrls(deployment = {}) {
        return deployment.external_url !== undefined
          && deployment.external_url_formatted !== undefined;
      },
      hasDeploymentTime(deployment = {}) {
        return deployment.deployed_at !== undefined
          && deployment.deployed_at_formatted !== undefined;
      },
      hasDeploymentMeta(deployment = {}) {
        return deployment.url !== undefined
          && deployment.name !== undefined;
      },
      stopEnvironment(deployment) {
        const isConfirmed = confirm(s__('mrWidget|Are you sure you want to stop this environment?')); // eslint-disable-line

        if (isConfirmed) {
          MRWidgetService.stopEnvironment(deployment.stop_url)
            .then(res => res.data)
            .then((data) => {
              if (data.redirect_url) {
                visitUrl(data.redirect_url);
              }
            })
            .catch(() => Flash(s__('mrWidget|Something went wrong while stopping this environment. Please try again.')));
        }
      },
    },
  };
</script>
<template>
  <div class="mr-widget-heading deploy-heading">
    <div
      v-for="(deployment, i) in deployments"
      :key="i"
      class="js-deploy-block"
    >
      <div class="ci-widget media">
        <div class="ci-status-icon ci-status-icon-success">
          <span class="js-icon-link icon-link">
            <status-icon status="success" />
          </span>
        </div>

        <div class="media-body space-children">
          <span>
            <template v-if="hasDeploymentMeta(deployment)">
              {{ s__("mrWidget|Deployed to") }}
              <a
                v-if="hasDeploymentMeta(deployment)"
                :href="deployment.url"
                target="_blank"
                rel="noopener noreferrer nofollow"
                class="js-deploy-meta inline"
              >
                {{ deployment.name }}
              </a>
            </template>
            <template v-if="hasExternalUrls(deployment)">
              on
              <a
                v-if="hasExternalUrls(deployment)"
                :href="deployment.external_url"
                target="_blank"
                rel="noopener noreferrer nofollow"
                class="js-deploy-url inline"
              >
                <i
                  class="fa fa-external-link"
                  aria-hidden="true"
                >
                </i>
                {{ deployment.external_url_formatted }}
              </a>
            </template>

            <span
              v-if="hasDeploymentTime(deployment)"
              :title="deployment.deployed_at_formatted"
              class="js-deploy-time"
              data-toggle="tooltip"
              data-placement="top"
              v-tooltip
            >
              {{ formatDate(deployment.deployed_at) }}
            </span>
          </span>
          <button
            type="button"
            v-if="deployment.stop_url"
            @click="stopEnvironment(deployment)"
            class="btn btn-default btn-sm js-stop-environment"
          >
            {{ s__("mrWidget|Stop environment") }}
          </button>

          <mr-widget-memory-usage
            v-if="deployment.metrics_url"
            :metrics-url="deployment.metrics_url"
            :metrics-monitoring-url="deployment.metrics_monitoring_url"
          />
        </div>
      </div>
    </div>
  </div>
</template>
