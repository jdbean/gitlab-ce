/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-underscore-dangle, prefer-arrow-callback, max-len, one-var, one-var-declaration-per-line, no-unused-vars, object-shorthand, comma-dangle, no-else-return, no-self-compare, consistent-return, no-param-reassign, no-shadow */
/* global Issuable */
/* global ListMilestone */
import _ from 'underscore';
import axios from './lib/utils/axios_utils';
import { timeFor } from './lib/utils/datetime_utility';

export default class MilestoneSelect {
  constructor(currentProject, els, options = {}) {
    if (currentProject !== null) {
      this.currentProject = typeof currentProject === 'string' ? JSON.parse(currentProject) : currentProject;
    }

    this.init(els, options);
  }

  init(els, options) {
    let $els = $(els);

    if (!els) {
      $els = $('.js-milestone-select');
    }

    $els.each((i, dropdown) => {
      let collapsedSidebarLabelTemplate, milestoneLinkNoneTemplate, milestoneLinkTemplate, selectedMilestone, selectedMilestoneDefault;
      const $dropdown = $(dropdown);
      const projectId = $dropdown.data('project-id');
      const milestonesUrl = $dropdown.data('milestones');
      const issueUpdateURL = $dropdown.data('issueUpdate');
      const showNo = $dropdown.data('show-no');
      const showAny = $dropdown.data('show-any');
      const showMenuAbove = $dropdown.data('showMenuAbove');
      const showUpcoming = $dropdown.data('show-upcoming');
      const showStarted = $dropdown.data('show-started');
      const useId = $dropdown.data('use-id');
      const defaultLabel = $dropdown.data('default-label');
      const defaultNo = $dropdown.data('default-no');
      const issuableId = $dropdown.data('issuable-id');
      const abilityName = $dropdown.data('ability-name');
      const $selectBox = $dropdown.closest('.selectbox');
      const $block = $selectBox.closest('.block');
      const $sidebarCollapsedValue = $block.find('.sidebar-collapsed-icon');
      const $value = $block.find('.value');
      const $loading = $block.find('.block-loading').fadeOut();
      selectedMilestoneDefault = (showAny ? '' : null);
      selectedMilestoneDefault = (showNo && defaultNo ? 'No Milestone' : selectedMilestoneDefault);
      selectedMilestone = $dropdown.data('selected') || selectedMilestoneDefault;

      if (issueUpdateURL) {
        milestoneLinkTemplate = _.template('<a href="/<%- full_path %>/milestones/<%- iid %>" class="bold has-tooltip" data-container="body" title="<%- remaining %>"><%- title %></a>');
        milestoneLinkNoneTemplate = '<span class="no-value">None</span>';
        collapsedSidebarLabelTemplate = _.template('<span class="has-tooltip" data-container="body" title="<%- name %><br /><%- remaining %>" data-placement="left" data-html="true"> <%- title %> </span>');
      }
      return $dropdown.glDropdown({
        showMenuAbove: showMenuAbove,
        data: (term, callback) => axios.get(milestonesUrl)
          .then(({ data }) => {
            const extraOptions = [];
            if (showAny) {
              extraOptions.push({
                id: 0,
                name: '',
                title: 'Any Milestone'
              });
            }
            if (showNo) {
              extraOptions.push({
                id: -1,
                name: 'No Milestone',
                title: 'No Milestone'
              });
            }
            if (showUpcoming) {
              extraOptions.push({
                id: -2,
                name: '#upcoming',
                title: 'Upcoming'
              });
            }
            if (showStarted) {
              extraOptions.push({
                id: -3,
                name: '#started',
                title: 'Started'
              });
            }
            if (extraOptions.length) {
              extraOptions.push('divider');
            }

            callback(extraOptions.concat(data));
            if (showMenuAbove) {
              $dropdown.data('glDropdown').positionMenuAbove();
            }
            $(`[data-milestone-id="${selectedMilestone}"] > a`).addClass('is-active');
          }),
        renderRow: milestone => `
          <li data-milestone-id="${milestone.name}">
            <a href='#' class='dropdown-menu-milestone-link'>
              ${_.escape(milestone.title)}
            </a>
          </li>
        `,
        filterable: true,
        search: {
          fields: ['title']
        },
        selectable: true,
        toggleLabel: (selected, el, e) => {
          if (selected && 'id' in selected && $(el).hasClass('is-active')) {
            return selected.title;
          } else {
            return defaultLabel;
          }
        },
        defaultLabel: defaultLabel,
        fieldName: $dropdown.data('field-name'),
        text: milestone => _.escape(milestone.title),
        id: (milestone) => {
          if (!useId && !$dropdown.is('.js-issuable-form-dropdown')) {
            return milestone.name;
          } else {
            return milestone.id;
          }
        },
        isSelected: milestone => milestone.name === selectedMilestone,
        hidden: () => {
          $selectBox.hide();
          // display:block overrides the hide-collapse rule
          return $value.css('display', '');
        },
        opened: (e) => {
          const $el = $(e.currentTarget);
          if ($dropdown.hasClass('js-issue-board-sidebar') || options.handleClick) {
            selectedMilestone = $dropdown[0].dataset.selected || selectedMilestoneDefault;
          }
          $('a.is-active', $el).removeClass('is-active');
          $(`[data-milestone-id="${selectedMilestone}"] > a`, $el).addClass('is-active');
        },
        vue: $dropdown.hasClass('js-issue-board-sidebar'),
        clicked: (clickEvent) => {
          const { $el, e } = clickEvent;
          let selected = clickEvent.selectedObj;

          let data, boardsStore;
          if (!selected) return;

          if (options.handleClick) {
            e.preventDefault();
            options.handleClick(selected);
            return;
          }

          const page = $('body').attr('data-page');
          const isIssueIndex = page === 'projects:issues:index';
          const isMRIndex = (page === page && page === 'projects:merge_requests:index');
          const isSelecting = (selected.name !== selectedMilestone);
          selectedMilestone = isSelecting ? selected.name : selectedMilestoneDefault;
          if ($dropdown.hasClass('js-filter-bulk-update') || $dropdown.hasClass('js-issuable-form-dropdown')) {
            e.preventDefault();
            return;
          }

          if ($dropdown.closest('.add-issues-modal').length) {
            boardsStore = gl.issueBoards.ModalStore.store.filter;
          }

          if (boardsStore) {
            boardsStore[$dropdown.data('field-name')] = selected.name;
            e.preventDefault();
          } else if ($dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex)) {
            return Issuable.filterResults($dropdown.closest('form'));
          } else if ($dropdown.hasClass('js-filter-submit')) {
            return $dropdown.closest('form').submit();
          } else if ($dropdown.hasClass('js-issue-board-sidebar')) {
            if (selected.id !== -1 && isSelecting) {
              gl.issueBoards.boardStoreIssueSet('milestone', new ListMilestone({
                id: selected.id,
                title: selected.name
              }));
            } else {
              gl.issueBoards.boardStoreIssueDelete('milestone');
            }

            $dropdown.trigger('loading.gl.dropdown');
            $loading.removeClass('hidden').fadeIn();

            gl.issueBoards.BoardsStore.detail.issue.update($dropdown.attr('data-issue-update'))
              .then(() => {
                $dropdown.trigger('loaded.gl.dropdown');
                $loading.fadeOut();
              })
              .catch(() => {
                $loading.fadeOut();
              });
          } else {
            selected = $selectBox.find('input[type="hidden"]').val();
            data = {};
            data[abilityName] = {};
            data[abilityName].milestone_id = selected != null ? selected : null;
            $loading.removeClass('hidden').fadeIn();
            $dropdown.trigger('loading.gl.dropdown');
            return axios.put(issueUpdateURL, data)
              .then(({ data }) => {
                $dropdown.trigger('loaded.gl.dropdown');
                $loading.fadeOut();
                $selectBox.hide();
                $value.css('display', '');
                if (data.milestone != null) {
                  data.milestone.full_path = this.currentProject.full_path;
                  data.milestone.remaining = timeFor(data.milestone.due_date);
                  data.milestone.name = data.milestone.title;
                  $value.html(milestoneLinkTemplate(data.milestone));
                  return $sidebarCollapsedValue.find('span').html(collapsedSidebarLabelTemplate(data.milestone));
                } else {
                  $value.html(milestoneLinkNoneTemplate);
                  return $sidebarCollapsedValue.find('span').text('No');
                }
              });
          }
        }
      });
    });
  }
}
