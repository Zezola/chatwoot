/* global axios */

import ApiClient from 'dashboard/api/ApiClient';

class AccountScopedKanbanAPI extends ApiClient {
  constructor() {
    super('virti/kanban', { accountScoped: true });
  }

  getCurrent() {
    return axios.get(this.url);
  }

  getUser(userId) {
    return axios.get(`${this.url}/users/${userId}`);
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

  getUserModels() {
    return axios.get(`${this.url}/user_models`);
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

  getCards(modelId, options = {}) {
    const params = typeof options === 'number' ? { limit: options } : options;
    return axios.get(`${this.url}/models/${modelId}/cards`, { params });
  }

  getColumnCards(modelId, columnId, params = {}) {
    return axios.get(`${this.url}/models/${modelId}/columns/${columnId}/cards`, { params });
  }

  moveCard(modelId, payload) {
    return axios.post(`${this.url}/models/${modelId}/cards/move`, payload);
  }
}

export default class VirtiKanbanAPI {
  constructor() {
    this.accountScoped = new AccountScopedKanbanAPI();
  }

  getCurrent() {
    return this.accountScoped.getCurrent();
  }

  getUser(userId) {
    return this.accountScoped.getUser(userId);
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

  getUserModels() {
    return this.accountScoped.getUserModels();
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

  getCards(modelId, options) {
    return this.accountScoped.getCards(modelId, options);
  }

  getColumnCards(modelId, columnId, params) {
    return this.accountScoped.getColumnCards(modelId, columnId, params);
  }

  moveCard(modelId, payload) {
    return this.accountScoped.moveCard(modelId, payload);
  }
}
