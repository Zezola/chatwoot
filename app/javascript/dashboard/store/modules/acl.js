import * as types from '../mutation-types';

import VirtiAclAPI from 'dashboard/virti/acl/api';
import { DEFAULT_ACL, permissiveAcl } from 'dashboard/virti/acl/defaults';

const state = {
  currentUserACL: DEFAULT_ACL,
  editingACL: {},
};

export const getters = {
  getUserACL: $state => $state.currentUserACL,
  getEditingACL: $state => $state.editingACL,
};

export const actions = {
  fetchAcl: async ({ commit }) => {
    try {
      const aclapi = new VirtiAclAPI();
      const result = await aclapi.getCurrent();
      commit(types.default.SET_ACL, { ...result.data, exibir_acl: true });
    } catch (e) {
      console.error(e);
      commit(types.default.SET_ACL, permissiveAcl({ exibir_acl: false }));
    }
  },

  fetchEditingAcl: async ({ commit }, userId) => {
    const aclapi = new VirtiAclAPI();
    const result = await aclapi.getUser(userId);
    commit(types.default.SET_EDITING_ACL, result.data);
  },

  updateAcl: async ({ commit }, { userId, newAcl }) => {
    const aclapi = new VirtiAclAPI();
    await aclapi.updateUser(userId, newAcl);
  },
};

export const mutations = {
  [types.default.SET_ACL]($state, data) {
    // Troca cada membro do state individualmente
    const { userId, ...aclData } = data;
    $state.currentUserACL = { ...aclData };
    // Object.keys(data).forEach(key => {
    //     $state[key] = data[key]
    // })
  },

  [types.default.SET_EDITING_ACL]($state, data) {
    const { userId, ...aclData } = data;
    $state.editingACL = { ...aclData };
  },

  [types.default.UPDATE_ACL]($state, aclData) {
    $state.editingACL = { ...aclData };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
