/* global axios */

import ApiClient from 'dashboard/api/ApiClient';

class LegacyAclAPI extends ApiClient {
  constructor() {
    super('acl');
  }

  baseUrl() {
    return '';
  }
}

class AccountScopedAclAPI extends ApiClient {
  constructor() {
    super('virti/acl', { accountScoped: true });
  }

  hasAccountScope() {
    return Boolean(this.accountIdFromRoute);
  }

  getCurrent() {
    return axios.get(this.url);
  }

  getUser(userId) {
    return axios.get(`${this.url}/${userId}`);
  }

  updateUser(userId, permissions) {
    return axios.patch(`${this.url}/${userId}`, { permissions });
  }

  getModels() {
    return axios.get(`${this.url}/models`);
  }

  createModel(model) {
    return axios.post(`${this.url}/models`, { model });
  }

  updateModel(modelId, model) {
    return axios.patch(`${this.url}/models/${modelId}`, { model });
  }

  deleteModel(modelId) {
    return axios.delete(`${this.url}/models/${modelId}`);
  }

  getUserModel(userId) {
    return axios.get(`${this.url}/users/${userId}/model`);
  }

  updateUserModel(userId, modelId) {
    return axios.put(`${this.url}/users/${userId}/model`, { model_id: modelId });
  }

  deleteUserModel(userId) {
    return axios.delete(`${this.url}/users/${userId}/model`);
  }
}

export default class VirtiAclAPI {
  constructor() {
    this.accountScoped = new AccountScopedAclAPI();
    this.legacy = new LegacyAclAPI();
  }

  getCurrent() {
    if (this.accountScoped.hasAccountScope()) {
      return this.accountScoped.getCurrent();
    }

    return this.legacy.get();
  }

  getUser(userId) {
    if (this.accountScoped.hasAccountScope()) {
      return this.accountScoped.getUser(userId);
    }

    return this.legacy.show(userId);
  }

  updateUser(userId, permissions) {
    if (this.accountScoped.hasAccountScope()) {
      return this.accountScoped.updateUser(userId, permissions);
    }

    return this.legacy.update(userId, permissions);
  }

  getModels() {
    return this.accountScoped.getModels();
  }

  createModel(model) {
    return this.accountScoped.createModel(model);
  }

  updateModel(modelId, model) {
    return this.accountScoped.updateModel(modelId, model);
  }

  deleteModel(modelId) {
    return this.accountScoped.deleteModel(modelId);
  }

  getUserModel(userId) {
    return this.accountScoped.getUserModel(userId);
  }

  updateUserModel(userId, modelId) {
    return this.accountScoped.updateUserModel(userId, modelId);
  }

  deleteUserModel(userId) {
    return this.accountScoped.deleteUserModel(userId);
  }
}
