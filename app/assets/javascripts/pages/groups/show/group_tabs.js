import $ from 'jquery';
import { HIDDEN_CLASS } from '~/lib/utils/constants';
import { objectToQueryString } from '~/lib/utils/common_utils';
import { removeParams } from '~/lib/utils/url_utility';
import createGroupTree from '~/groups';
import {
  ACTIVE_TAB_OVERVIEW,
  ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
  ACTIVE_TAB_SHARED,
  ACTIVE_TAB_ARCHIVED,
  CONTENT_LIST_CLASS,
  GROUPS_LIST_HOLDER_CLASS,
  MAX_OVERVIEW_COUNT,
} from '~/groups/constants';
import UserTabs from '~/pages/users/user_tabs';
import GroupFilterableList from '~/groups/groups_filterable_list';

export default class GroupTabs extends UserTabs {
  constructor({ defaultAction = 'overview', action, parentEl }) {
    super({ defaultAction, action, parentEl });
  }

  bindEvents() {
    this.$parentEl
      .off('shown.bs.tab', '.nav-links a[data-toggle="tab"]')
      .on('shown.bs.tab', '.nav-links a[data-toggle="tab"]', event => this.tabShown(event))
      .on('click', '.card-footer a[data-action]', event => this.onCardFooterLinkClick(event));

    this.debounceOverviewFilterInput = _.debounce(
      this.onOverviewFilterInput.bind(this),
      WAIT_INTERVAL,
    );
    this.$parentEl.on('input', '#overview input[name=filter]', this.debounceOverviewFilterInput);
  }

  onCardFooterLinkClick(e) {
    e.preventDefault();
    const $target = $(e.target);
    const action = $target.data('action');

    this.tabShown(e);
    this.activateTab(action);
  }

  onOverviewFilterInput(e) {
    const { targetSection } = e.target.dataset;
    const searchQuery = e.target.value;
    const targetInputEl = document.querySelector('.nav-controls input[name=filter]');

    targetInputEl.value = searchQuery;
    this.tabShown(e);
    this.activateTab(targetSection);
    setTimeout(() => {
      targetInputEl.dispatchEvent(new Event('input'));
      targetInputEl.focus();
    }, 250);
  }

  tabShown(event) {
    const $target = $(event.target);
    const action = $target.data('action') || $target.data('targetSection');
    const source = $target.attr('href') || $target.data('targetPath');

    this.setTab(action);
    return this.setCurrentAction(source);
  }

  setTab(action) {
    const loadableActions = [
      ACTIVE_TAB_OVERVIEW,
      ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
      ACTIVE_TAB_SHARED,
      ACTIVE_TAB_ARCHIVED,
    ];
    this.enableSearchBar(action);

    if (this.loaded[action]) {
      return;
    }

    if (loadableActions.indexOf(action) > -1) {
      this.checkFilterState();
      this.loadTab(action);
    }
  }

  loadTab(action) {
    const isSubTree = action !== ACTIVE_TAB_OVERVIEW;
    const treesToLoad = [];

    switch (action) {
      case ACTIVE_TAB_OVERVIEW:
        treesToLoad.push(
          {
            elId: 'js-groups-overview-children-tree',
            endpoint: this.getEndpoint(`${ACTIVE_TAB_OVERVIEW}-children`),
          },
          {
            elId: 'js-groups-overview-shared-tree',
            endpoint: this.getEndpoint(`${ACTIVE_TAB_OVERVIEW}-shared`),
          },
        );
        break;
      default:
        treesToLoad.push({
          elId: `js-groups-${action}-tree`,
          endpoint: this.getEndpoint(action),
        });
        break;
    }

    this.toggleLoading(true);

    treesToLoad.forEach(tree => {
      const { elId, endpoint } = tree;
      createGroupTree(elId, endpoint, action, isSubTree);
    });
    this.loaded[action] = true;

    this.toggleLoading(false);
  }

  getEndpoint(action) {
    const { endpointsDefault, endpointsShared } = this.$parentEl.data();
    const overviewParams = {
      per_page: MAX_OVERVIEW_COUNT,
    };
    const archivedProjectsParams = {
      archived: 'only',
    };
    let endpoint;

    switch (action) {
      case ACTIVE_TAB_ARCHIVED:
        endpoint = `${endpointsDefault}?${objectToQueryString(archivedProjectsParams)}`;
        break;
      case ACTIVE_TAB_SHARED:
        endpoint = endpointsShared;
        break;
      case ACTIVE_TAB_SUBGROUPS_AND_PROJECTS:
        endpoint = endpointsDefault;
        break;
      case `${ACTIVE_TAB_OVERVIEW}-children`:
        endpoint = `${endpointsDefault}?${objectToQueryString(overviewParams)}`;
        break;
      case `${ACTIVE_TAB_OVERVIEW}-shared`:
        endpoint = `${endpointsShared}?${objectToQueryString(overviewParams)}`;
        break;
      default:
        endpoint = null;
        break;
    }

    return endpoint;
  }

  enableSearchBar(action) {
    const isOverview = action === ACTIVE_TAB_OVERVIEW;

    this.hideSearchBar(isOverview);

    if (isOverview) return;

    const containerEl = document.getElementById(action);
    const form = document.querySelector('form#group-filter-form');
    const filter = document.querySelector('.js-groups-list-filter');
    const holder = containerEl.querySelector(GROUPS_LIST_HOLDER_CLASS);
    const dataEl = containerEl.querySelector(CONTENT_LIST_CLASS);
    const { dataset } = dataEl;
    const endpoint = this.getEndpoint(action);

    const opts = {
      form,
      filter,
      holder,
      filterEndpoint: endpoint || dataset.endpoint,
      pagePath: null,
      dropdownSel: '.js-group-filter-dropdown-wrap',
      filterInputField: 'filter',
      action,
    };

    if (this.groupFilterList) {
      this.groupFilterList.unbindEvents();
    }

    this.groupFilterList = new GroupFilterableList(opts);
    this.groupFilterList.initSearch();
  }

  hideSearchBar(isOverview) {
    return this.$parentEl
      .find('.nav-controls .group-filter-form')
      .toggleClass(HIDDEN_CLASS, isOverview);
  }

  checkFilterState() {
    const values = Object.values(this.loaded);
    const loadedTabs = values.filter(e => e === true);

    if (loadedTabs.length > 0) {
      const newState = removeParams(['filter', 'page'], window.location.search);

      window.history.replaceState(
        {
          url: newState,
        },
        document.title,
        newState,
      );
    }

    return true;
  }
}
