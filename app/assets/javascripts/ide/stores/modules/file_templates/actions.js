import Api from '~/api';
import * as types from './mutation_types';

export const requestTemplateTypes = ({ commit }) => commit(types.REQUEST_TEMPLATE_TYPES);
export const receiveTemplateTypesError = ({ commit }) => commit(types.RECEIVE_TEMPLATE_TYPES_ERROR);
export const receiveTemplateTypesSuccess = ({ commit }, templates) =>
  commit(types.RECEIVE_TEMPLATE_TYPES_SUCCESS, templates);

export const fetchTemplateTypes = ({ dispatch, state }) => {
  if (state.selectedTemplateType === '') return Promise.reject();

  dispatch('requestTemplateTypes');

  return Api.templates(state.selectedTemplateType.key)
    .then(({ data }) => dispatch('receiveTemplateTypesSuccess', data))
    .catch(() => dispatch('receiveTemplateTypesSuccess'));
};

export const setTemplateType = ({ commit }, type) => commit(types.SET_TEMPLATE_TYPE, type);

export const updateFile = ({ dispatch, commit, rootGetters }, template) => {
  dispatch(
    'changeFileContent',
    { path: rootGetters.activeFile.path, content: template.content },
    { root: true },
  );
  commit(types.SET_UPDATE_SUCCESS, true);
};

export const fetchTemplate = ({ dispatch, state }, template) => {
  if (template.content) {
    dispatch('updateFile', template);
    return Promise.resolve();
  }

  return Api.templates(`${state.selectedTemplateType.key}/${template.key || template.name}`).then(
    ({ data }) => {
      dispatch('updateFile', data);
    },
  );
};

export default () => {};
