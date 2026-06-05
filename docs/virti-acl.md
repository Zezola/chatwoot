# Virti ACL

O módulo `Virti::Acl` centraliza as permissões customizadas da Virti dentro do Rails do Chatwoot.

## Conceitos

- **Modelo de ACL**: conjunto nomeado de permissões de uma conta. Fica em `virti_acl_models`.
- **Vínculo usuário-modelo**: associação explícita entre usuário, conta e modelo. Fica em `virti_acl_user_models`.
- **ACL individual**: configuração legada por usuário na tabela `Virti_UsuarioACL`.

Um usuário só usa um modelo quando existe vínculo explícito em `virti_acl_user_models`.
Permissões iguais às de um modelo não contam como vínculo.

## Origem das permissões

As APIs retornam `aclSource` para indicar de onde vieram as permissões efetivas:

- `model`: usuário tem um Modelo de ACL vinculado explicitamente na conta.
- `individual`: usuário não tem modelo, mas tem ACL individual em `Virti_UsuarioACL`.
- `default`: usuário não tem modelo nem ACL individual; usa permissões padrão.
- `disabled`: `VIRTI_ACL_ENABLED=false`; o módulo retorna permissões padrão.

Exemplo com modelo:

```json
{
  "userId": 102,
  "aclSource": "model",
  "model": {
    "id": 1,
    "name": "Corretor"
  }
}
```

Exemplo com ACL individual:

```json
{
  "userId": 62,
  "aclSource": "individual",
  "model": null
}
```

## Ordem de resolução

1. Se `VIRTI_ACL_ENABLED=false`, usa permissões padrão e `aclSource=disabled`.
2. Se o usuário tem modelo vinculado na conta, usa o modelo e `aclSource=model`.
3. Se não tem modelo, mas tem `Virti_UsuarioACL`, usa a ACL individual e `aclSource=individual`.
4. Se não tem nenhum dos dois, usa permissões padrão e `aclSource=default`.

## APIs

Permissões efetivas:

```text
GET /api/v1/accounts/:account_id/virti/acl
GET /api/v1/accounts/:account_id/virti/acl/:user_id
PATCH /api/v1/accounts/:account_id/virti/acl/:user_id
```

Modelos:

```text
GET    /api/v1/accounts/:account_id/virti/acl/permission_definitions
GET    /api/v1/accounts/:account_id/virti/acl/models
POST   /api/v1/accounts/:account_id/virti/acl/models
GET    /api/v1/accounts/:account_id/virti/acl/models/:id
PATCH  /api/v1/accounts/:account_id/virti/acl/models/:id
DELETE /api/v1/accounts/:account_id/virti/acl/models/:id
```

Vínculo usuário-modelo:

```text
GET    /api/v1/accounts/:account_id/virti/acl/users/:user_id/model
PUT    /api/v1/accounts/:account_id/virti/acl/users/:user_id/model
DELETE /api/v1/accounts/:account_id/virti/acl/users/:user_id/model
```

## Contrato de permissões

O campo `permissions` aceita apenas chaves conhecidas pelo catálogo de permissões e valores booleanos (`true` ou `false`).

Payloads com chaves desconhecidas ou valores como string (`"false"`) são rejeitados com `422 Unprocessable Entity`.

No `PATCH /models/:id`, se `permissions` for omitido, as permissões atuais do modelo são preservadas. Se `permissions` for enviado, o mapa enviado substitui o mapa anterior após validação e normalização.

## Administradores

Administradores da conta podem gerenciar modelos, vínculos e ACLs individuais.

Nas regras operacionais, administradores também obedecem ao modelo atribuído. Ou seja, um administrador com modelo restritivo também terá listagem, acesso direto, atribuições e notificações limitadas por esse modelo.

## Feature flag

```env
VIRTI_ACL_ENABLED=true
```

Se `false`, o módulo fica permissivo e não aplica enforcement.

## Enforcement atual

O Rails aplica ACL em:

- listagem, busca, meta e filtros de conversas;
- acesso direto a conversa;
- atribuições de conversa.
- criação de notificações de conversa (`NotificationBuilder`), incluindo sininho, push e email;
- listagem e contagem de notificações antigas (`NotificationFinder`).

Notificações que não são relacionadas a conversas continuam fora da regra de ACL de conversa.

Eventos realtime de conversa via ActionCable são um fluxo separado e ainda devem ser avaliados em fase própria.

## Exclusão de modelos

Modelos sem usuários vinculados são removidos fisicamente.

Modelos em uso não são removidos e a API retorna `409 Conflict`.

## chatwoot-virti-custom

O `chatwoot-virti-custom` ainda pode existir para integrações Virti em `/api/v1/virti/*` e para o endpoint legado `/acl` enquanto houver fallback.

As rotas de acesso direto a conversa e atribuições devem ser atendidas pelo Rails, que já aplica o enforcement do `Virti::Acl`.
