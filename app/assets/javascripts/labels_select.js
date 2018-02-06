/* eslint-disable no-useless-return, func-names, space-before-function-paren, wrap-iife, no-var, no-underscore-dangle, prefer-arrow-callback, max-len, one-var, no-unused-vars, one-var-declaration-per-line, prefer-template, no-new, consistent-return, object-shorthand, comma-dangle, no-shadow, no-param-reassign, brace-style, vars-on-top, quotes, no-lonely-if, no-else-return, dot-notation, no-empty, no-return-assign, camelcase, prefer-spread */
/* global Issuable */
/* global ListLabel */
import _ from 'underscore';
import { __ } from './locale';
import axios from './lib/utils/axios_utils';
import IssuableBulkUpdateActions from './issuable_bulk_update_actions';
import DropdownUtils from './filtered_search/dropdown_utils';
import CreateLabelDropdown from './create_label';
import flash from './flash';

export default class LabelsSelect {
  constructor(els, options = {}) {
    var _this, $els;
    _this = this;

    $els = $(els);

    if (!els) {
      $els = $('.js-label-select');
    }

    $els.each(function(i, dropdown) {
      var $block, $colorPreview, $dropdown, $form, $loading, $selectbox, $sidebarCollapsedValue, $value, abilityName, defaultLabel, enableLabelCreateButton, issueURLSplit, issueUpdateURL, labelHTMLTemplate, labelNoneHTMLTemplate, labelUrl, namespacePath, projectPath, saveLabelData, selectedLabel, showAny, showNo, $sidebarLabelTooltip, initialSelected, $toggleText, fieldName, useId, propertyName, showMenuAbove, $container, $dropdownContainer;
      $dropdown = $(dropdown);
      $dropdownContainer = $dropdown.closest('.labels-filter');
      $toggleText = $dropdown.find('.dropdown-toggle-text');
      namespacePath = $dropdown.data('namespace-path');
      projectPath = $dropdown.data('project-path');
      labelUrl = $dropdown.data('labels');
      issueUpdateURL = $dropdown.data('issueUpdate');
      selectedLabel = $dropdown.data('selected');
      if ((selectedLabel != null) && !$dropdown.hasClass('js-multiselect')) {
        selectedLabel = selectedLabel.split(',');
      }
      showNo = $dropdown.data('show-no');
      showAny = $dropdown.data('show-any');
      showMenuAbove = $dropdown.data('showMenuAbove');
      defaultLabel = $dropdown.data('default-label');
      abilityName = $dropdown.data('ability-name');
      $selectbox = $dropdown.closest('.selectbox');
      $block = $selectbox.closest('.block');
      $form = $dropdown.closest('form, .js-issuable-update');
      $sidebarCollapsedValue = $block.find('.sidebar-collapsed-icon span');
      $sidebarLabelTooltip = $block.find('.js-sidebar-labels-tooltip');
      $value = $block.find('.value');
      $loading = $block.find('.block-loading').fadeOut();
      fieldName = $dropdown.data('field-name');
      useId = $dropdown.is('.js-issuable-form-dropdown, .js-filter-bulk-update, .js-label-sidebar-dropdown');
      propertyName = useId ? 'id' : 'title';
      initialSelected = $selectbox
        .find('input[name="' + $dropdown.data('field-name') + '"]')
        .map(function () {
          return this.value;
        }).get();
      if (issueUpdateURL != null) {
        issueURLSplit = issueUpdateURL.split('/');
      }
      if (issueUpdateURL) {
        labelHTMLTemplate = _.template('<% _.each(labels, function(label){ %> <a href="<%- ["",issueURLSplit[1], issueURLSplit[2],""].join("/") %>issues?label_name[]=<%- encodeURIComponent(label.title) %>"> <span class="label has-tooltip color-label" title="<%- label.description %>" style="background-color: <%- label.color %>; color: <%- label.text_color %>;"> <%- label.title %> </span> </a> <% }); %>');
        labelNoneHTMLTemplate = '<span class="no-value">None</span>';
      }
      const handleClick = options.handleClick;

      $sidebarLabelTooltip.tooltip();

      if ($dropdown.closest('.dropdown').find('.dropdown-new-label').length) {
        new CreateLabelDropdown($dropdown.closest('.dropdown').find('.dropdown-new-label'), namespacePath, projectPath);
      }

      saveLabelData = function() {
        var data, selected;
        selected = $dropdown.closest('.selectbox').find("input[name='" + fieldName + "']").map(function() {
          return this.value;
        }).get();

        if (_.isEqual(initialSelected, selected)) return;
        initialSelected = selected;

        data = {};
        data[abilityName] = {};
        data[abilityName].label_ids = selected;
        if (!selected.length) {
          data[abilityName].label_ids = [''];
        }
        $loading.removeClass('hidden').fadeIn();
        $dropdown.trigger('loading.gl.dropdown');
        axios.put(issueUpdateURL, data)
          .then(({ data }) => {
            var labelCount, template, labelTooltipTitle, labelTitles;
            $loading.fadeOut();
            $dropdown.trigger('loaded.gl.dropdown');
            $selectbox.hide();
            data.issueURLSplit = issueURLSplit;
            labelCount = 0;
            if (data.labels.length) {
              template = labelHTMLTemplate(data);
              labelCount = data.labels.length;
            }
            else {
              template = labelNoneHTMLTemplate;
            }
            $value.removeAttr('style').html(template);
            $sidebarCollapsedValue.text(labelCount);

            if (data.labels.length) {
              labelTitles = data.labels.map(function(label) {
                return label.title;
              });

              if (labelTitles.length > 5) {
                labelTitles = labelTitles.slice(0, 5);
                labelTitles.push('and ' + (data.labels.length - 5) + ' more');
              }

              labelTooltipTitle = labelTitles.join(', ');
            }
            else {
              labelTooltipTitle = '';
              $sidebarLabelTooltip.tooltip('destroy');
            }

            $sidebarLabelTooltip
              .attr('title', labelTooltipTitle)
              .tooltip('fixTitle');

            $('.has-tooltip', $value).tooltip({
              container: 'body'
            });
          })
          .catch(() => flash(__('Error saving label update.')));
      };
      $dropdown.glDropdown({
        showMenuAbove: showMenuAbove,
        data: function(term, callback) {
          axios.get(labelUrl)
            .then((res) => {
              let data = _.chain(res.data).groupBy(function(label) {
                return label.title;
              }).map(function(label) {
                var color;
                color = _.map(label, function(dup) {
                  return dup.color;
                });
                return {
                  id: label[0].id,
                  title: label[0].title,
                  color: color,
                  duplicate: color.length > 1
                };
              }).value();
              if ($dropdown.hasClass('js-extra-options')) {
                var extraData = [];
                if (showNo) {
                  extraData.unshift({
                    id: 0,
                    title: 'No Label'
                  });
                }
                if (showAny) {
                  extraData.unshift({
                    isAny: true,
                    title: 'Any Label'
                  });
                }
                if (extraData.length) {
                  extraData.push('divider');
                  data = extraData.concat(data);
                }
              }

              callback(data);
              if (showMenuAbove) {
                $dropdown.data('glDropdown').positionMenuAbove();
              }
            })
            .catch(() => flash(__('Error fetching labels.')));
        },
        renderRow: function(label, instance) {
          var $a, $li, color, colorEl, indeterminate, removesAll, selectedClass, spacing, i, marked, dropdownName, dropdownValue;
          $li = $('<li>');
          $a = $('<a href="#">');
          selectedClass = [];
          removesAll = label.id <= 0 || (label.id == null);
          if ($dropdown.hasClass('js-filter-bulk-update')) {
            indeterminate = $dropdown.data('indeterminate') || [];
            marked = $dropdown.data('marked') || [];

            if (indeterminate.indexOf(label.id) !== -1) {
              selectedClass.push('is-indeterminate');
            }

            if (marked.indexOf(label.id) !== -1) {
              // Remove is-indeterminate class if the item will be marked as active
              i = selectedClass.indexOf('is-indeterminate');
              if (i !== -1) {
                selectedClass.splice(i, 1);
              }
              selectedClass.push('is-active');
            }
          } else {
            if (this.id(label)) {
              dropdownName = $dropdown.data('fieldName');
              dropdownValue = this.id(label).toString().replace(/'/g, '\\\'');

              if ($form.find("input[type='hidden'][name='" + dropdownName + "'][value='" + dropdownValue + "']").length) {
                selectedClass.push('is-active');
              }
            }

            if ($dropdown.hasClass('js-multiselect') && removesAll) {
              selectedClass.push('dropdown-clear-active');
            }
          }
          if (label.duplicate) {
            color = gl.DropdownUtils.duplicateLabelColor(label.color);
          }
          else {
            if (label.color != null) {
              color = label.color[0];
            }
          }
          if (color) {
            colorEl = "<span class='dropdown-label-box' style='background: " + color + "'></span>";
          }
          else {
            colorEl = '';
          }
          // We need to identify which items are actually labels
          if (label.id) {
            selectedClass.push('label-item');
            $a.attr('data-label-id', label.id);
          }
          $a.addClass(selectedClass.join(' ')).html(`${colorEl} ${_.escape(label.title)}`);
          // Return generated html
          return $li.html($a).prop('outerHTML');
        },
        search: {
          fields: ['title']
        },
        selectable: true,
        filterable: true,
        selected: $dropdown.data('selected') || [],
        toggleLabel: function(selected, el) {
          var isSelected = el !== null ? el.hasClass('is-active') : false;
          var title = selected.title;
          var selectedLabels = this.selected;

          if (selected.id === 0) {
            this.selected = [];
            return 'No Label';
          }
          else if (isSelected) {
            this.selected.push(title);
          }
          else {
            var index = this.selected.indexOf(title);
            this.selected.splice(index, 1);
          }

          if (selectedLabels.length === 1) {
            return selectedLabels;
          }
          else if (selectedLabels.length) {
            return selectedLabels[0] + " +" + (selectedLabels.length - 1) + " more";
          }
          else {
            return defaultLabel;
          }
        },
        fieldName: $dropdown.data('field-name'),
        id: function(label) {
          if (label.id <= 0) return label.title;

          if ($dropdown.hasClass('js-issuable-form-dropdown')) {
            return label.id;
          }

          if ($dropdown.hasClass("js-filter-submit") && (label.isAny == null)) {
            return label.title;
          }
          else {
            return label.id;
          }
        },
        hidden: function() {
          var isIssueIndex, isMRIndex, page, selectedLabels;
          page = $('body').attr('data-page');
          isIssueIndex = page === 'projects:issues:index';
          isMRIndex = page === 'projects:merge_requests:index';
          $selectbox.hide();
          // display:block overrides the hide-collapse rule
          $value.removeAttr('style');

          if ($dropdown.hasClass('js-issuable-form-dropdown')) {
            return;
          }

          if ($('html').hasClass('issue-boards-page')) {
            return;
          }
          if ($dropdown.hasClass('js-multiselect')) {
            if ($dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex)) {
              selectedLabels = $dropdown.closest('form').find("input:hidden[name='" + ($dropdown.data('fieldName')) + "']");
              Issuable.filterResults($dropdown.closest('form'));
            }
            else if ($dropdown.hasClass('js-filter-submit')) {
              $dropdown.closest('form').submit();
            }
            else {
              if (!$dropdown.hasClass('js-filter-bulk-update')) {
                saveLabelData();
              }
            }
          }
        },
        multiSelect: $dropdown.hasClass('js-multiselect'),
        vue: $dropdown.hasClass('js-issue-board-sidebar'),
        clicked: function(options) {
          const { $el, e, isMarking } = options;
          const label = options.selectedObj;

          var isIssueIndex, isMRIndex, page, boardsModel;
          var fadeOutLoader = () => {
            $loading.fadeOut();
          };

          page = $('body').attr('data-page');
          isIssueIndex = page === 'projects:issues:index';
          isMRIndex = page === 'projects:merge_requests:index';

          if ($dropdown.parent().find('.is-active:not(.dropdown-clear-active)').length) {
            $dropdown.parent()
              .find('.dropdown-clear-active')
              .removeClass('is-active');
          }

          if ($dropdown.hasClass('js-issuable-form-dropdown')) {
            return;
          }

          if ($dropdown.hasClass('js-filter-bulk-update')) {
            _this.enableBulkLabelDropdown();
            _this.setDropdownData($dropdown, isMarking, label.id);
            return;
          }

          if ($dropdown.closest('.add-issues-modal').length) {
            boardsModel = gl.issueBoards.ModalStore.store.filter;
          }

          if (boardsModel) {
            if (label.isAny) {
              boardsModel['label_name'] = [];
            } else if ($el.hasClass('is-active')) {
              boardsModel['label_name'].push(label.title);
            }

            e.preventDefault();
            return;
          }
          else if ($dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex)) {
            if (!$dropdown.hasClass('js-multiselect')) {
              selectedLabel = label.title;
              return Issuable.filterResults($dropdown.closest('form'));
            }
          }
          else if ($dropdown.hasClass('js-filter-submit')) {
            return $dropdown.closest('form').submit();
          }
          else if ($dropdown.hasClass('js-issue-board-sidebar')) {
            if ($el.hasClass('is-active')) {
              gl.issueBoards.BoardsStore.detail.issue.labels.push(new ListLabel({
                id: label.id,
                title: label.title,
                color: label.color[0],
                textColor: '#fff'
              }));
            }
            else {
              var labels = gl.issueBoards.BoardsStore.detail.issue.labels;
              labels = labels.filter(function (selectedLabel) {
                return selectedLabel.id !== label.id;
              });
              gl.issueBoards.BoardsStore.detail.issue.labels = labels;
            }

            $loading.fadeIn();

            gl.issueBoards.BoardsStore.detail.issue.update($dropdown.attr('data-issue-update'))
              .then(fadeOutLoader)
              .catch(fadeOutLoader);
          }
          else if (handleClick) {
            e.preventDefault();
            handleClick(label);
          }
          else {
            if ($dropdown.hasClass('js-multiselect')) {

            }
            else {
              return saveLabelData();
            }
          }
        },
      });

      // Set dropdown data
      _this.setOriginalDropdownData($dropdownContainer, $dropdown);
    });
    this.bindEvents();
  }

  bindEvents() {
    return $('body').on('change', '.selected_issue', this.onSelectCheckboxIssue);
  }
  // eslint-disable-next-line class-methods-use-this
  onSelectCheckboxIssue() {
    if ($('.selected_issue:checked').length) {
      return;
    }
    return $('.issues-bulk-update .labels-filter .dropdown-toggle-text').text('Label');
  }
  // eslint-disable-next-line class-methods-use-this
  enableBulkLabelDropdown() {
    IssuableBulkUpdateActions.willUpdateLabels = true;
  }
  // eslint-disable-next-line class-methods-use-this
  setDropdownData($dropdown, isMarking, value) {
    var i, markedIds, unmarkedIds, indeterminateIds;

    markedIds = $dropdown.data('marked') || [];
    unmarkedIds = $dropdown.data('unmarked') || [];
    indeterminateIds = $dropdown.data('indeterminate') || [];

    if (isMarking) {
      markedIds.push(value);

      i = indeterminateIds.indexOf(value);
      if (i > -1) {
        indeterminateIds.splice(i, 1);
      }

      i = unmarkedIds.indexOf(value);
      if (i > -1) {
        unmarkedIds.splice(i, 1);
      }
    } else {
      // If marked item (not common) is unmarked
      i = markedIds.indexOf(value);
      if (i > -1) {
        markedIds.splice(i, 1);
      }

      // If an indeterminate item is being unmarked
      if (IssuableBulkUpdateActions.getOriginalIndeterminateIds().indexOf(value) > -1) {
        unmarkedIds.push(value);
      }

      // If a marked item is being unmarked
      // (a marked item could also be a label that is present in all selection)
      if (IssuableBulkUpdateActions.getOriginalCommonIds().indexOf(value) > -1) {
        unmarkedIds.push(value);
      }
    }

    $dropdown.data('marked', markedIds);
    $dropdown.data('unmarked', unmarkedIds);
    $dropdown.data('indeterminate', indeterminateIds);
  }
  // eslint-disable-next-line class-methods-use-this
  setOriginalDropdownData($container, $dropdown) {
    const labels = [];
    $container.find('[name="label_name[]"]').map(function() {
      return labels.push(this.value);
    });
    $dropdown.data('marked', labels);
  }
}
