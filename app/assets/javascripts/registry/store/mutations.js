/* eslint-disable no-param-reassign */
import * as types from './mutation_types';
import { parseIntPagination, normalizeHeaders } from '../../lib/utils/common_utils';
import { findListToUpdate } from './utils';

export default {

  [types.SET_MAIN_ENDPOINT](state, endpoint) {
    state.endpoint = endpoint;
  },

  [types.REQUEST_REPOS_LIST](state) {
    state.isLoading = true;
  },

  [types.RECEIVE_REGISTRY_LIST_SUCCESS](state, list) {
    state.isLoading = false;

    state.repos = list.map((el) => ({
      canDelete: !!el.destroy_path,
      destroyPath: el.destroy_path,
      id: el.id,
      isLoading: false,
      list: [],
      location: el.location,
      name: el.path,
      tagsPath: el.tags_path,
    }));
  },

  [types.RECEIVE_REGISTRY_LIST_ERROR](state) {
    state.isLoading = false;
  },

  [types.REQUEST_REGISTRY_LIST](state, list) {
    const listToUpdate = findListToUpdate(state.repos, list);
    listToUpdate.isLoading = true;
  },

  [types.RECEIVE_REGISTRY_LIST_SUCCESS](state, response, list) {
    const listToUpdate = findListToUpdate(state.repos, list);

    const normalizedHeaders = normalizeHeaders(response.headers);
    const pagination = parseIntPagination(normalizedHeaders);

    listToUpdate.isLoading = false;
    listToUpdate.pagination = pagination;

    listToUpdate.list = response.data.map(element => ({
      tag: element.name,
      revision: element.revision,
      shortRevision: element.short_revision,
      size: element.total_size,
      layers: element.layers,
      location: element.location,
      createdAt: element.created_at,
      destroyPath: element.destroy_path,
      canDelete: !!element.destroy_path,
    }));
  },

  [types.RECEIVE_REGISTRY_LIST_ERROR](state, list) {
    const listToUpdate = findListToUpdate(state.repos, list);
    listToUpdate.isLoading = false;
  },
};
