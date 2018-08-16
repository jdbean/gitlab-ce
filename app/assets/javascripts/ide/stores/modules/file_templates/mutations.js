/* eslint-disable no-param-reassign */
import * as types from './mutation_types';

export default {
  [types.REQUEST_TEMPLATE_TYPES](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_TEMPLATE_TYPES_ERROR](state) {
    state.isLoading = false;
  },
  [types.RECEIVE_TEMPLATE_TYPES_SUCCESS](state, templates) {
    state.isLoading = false;
    state.templates = templates;
  },
  [types.SET_TEMPLATE_TYPE](state, type) {
    state.selectedTemplateType = type;
  },
  [types.SET_UPDATE_SUCCESS](state, success) {
    state.updateSuccess = success;
  },
};
