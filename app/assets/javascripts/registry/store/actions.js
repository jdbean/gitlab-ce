import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import * as types from './mutation_types';
import { errorMessages, errorMessagesTypes } from '../constants';

export const setMainEndpoint = ({ commit }, data) => commit(types.SET_MAIN_ENDPOINT, data);

export const requestReposList = ({ commit }) => commit(types.REQUEST_REPOS_LIST);
export const receiveReposListSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_REPOS_LIST_SUCCESS, response);
export const receiveReposListError = ({ commit }) => commit(types.RECEIVE_REPOS_LIST_SUCCESS);

export const fetchRepos = ({ state, dispatch }) => {
  dispatch('requestReposList');

  return axios
    .get(state.endpoint)
    .then(({ data }) => {
      dispatch('receiveReposListSuccess', data);
    })
    .catch(() => {
      dispatch('receiveReposListError');
      createFlash(errorMessages[errorMessagesTypes.FETCH_REPOS]);
    });
};

export const requestRegistryList = ({ commit }, list) => commit(types.REQUEST_REGISTRY_LIST, list);
export const receiveRegistryListSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_REGISTRY_LIST_SUCCESS, response);
export const receiveRegistryListError = ({ commit }) => commit(types.RECEIVE_REGISTRY_LIST_ERROR);

export const fetchList = ({ dispatch }, { repo, page }) => {
  dispatch('requestRegistryList', repo);

  return axios
    .get(repo.tagsPath, { params: { page } })
    .then(response => {
      dispatch('receiveRegistryListSuccess', response, repo);
    })
    .catch(() => {
      dispatch('receiveRegistryListError');
      createFlash(errorMessages[errorMessagesTypes.FETCH_REGISTRY]);
    });
};

export const deleteRepo = ({ dispatch }, repo) =>
  axios.delete(repo.destroyPath)
    .then(() => dispatch('fetchRepos'))
    .catch(() => createFlash(errorMessages[errorMessagesTypes.FETCH_REGISTRY]));

// eslint-disable-next-line no-unused-vars
export const deleteRegistry = ({ dispatch }, image, repo) =>
  axios.delete(image.destroyPath)
    .then(() => dispatch('fetchList', { repo }))
    .catch(() => createFlash(errorMessages[errorMessagesTypes.DELETE_REGISTRY]));

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
