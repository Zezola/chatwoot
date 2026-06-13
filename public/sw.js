/* eslint-disable no-restricted-globals, no-console */
/* globals clients */
self.addEventListener('push', event => {
  let notification = event.data && event.data.json();
  let receivedPromise = notification.receivedUrl
    ? fetch(notification.receivedUrl, { credentials: 'omit', mode: 'no-cors' }).catch(() => {})
    : Promise.resolve();

  event.waitUntil(
    Promise.all([
      receivedPromise,
      self.registration.showNotification(notification.title, {
        tag: notification.tag,
        data: {
          url: notification.url,
          clickUrl: notification.clickUrl,
        },
      }),
    ])
  );
});

self.addEventListener('notificationclick', event => {
  let notification = event.notification;
  notification.close();

  let trackClick = () => {
    if (!notification.data.clickUrl) return Promise.resolve();

    return fetch(`${notification.data.clickUrl}?track_only=1`, { credentials: 'omit', mode: 'no-cors' }).catch(() => {});
  };

  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(windowClients => {
      let matchingWindowClients = windowClients.filter(
        client => client.url === notification.data.url
      );

      if (matchingWindowClients.length) {
        let firstWindow = matchingWindowClients[0];
        if (firstWindow && 'focus' in firstWindow) {
          return trackClick().then(() => firstWindow.focus());
        }
      }
      if (clients.openWindow) {
        return trackClick().then(() => clients.openWindow(notification.data.url));
      }
      return trackClick();
    })
  );
});
