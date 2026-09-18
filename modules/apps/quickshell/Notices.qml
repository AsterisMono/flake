pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification lifecycle, banners and bounded session history.
//
// A record tracks the live notification object while its actions can still be
// invoked, and keeps a snapshot after the client has been told it closed. The
// drawer lists the history; banners are the transient half of the same record.
// There is no Undo, by request. Do Not Disturb pauses banners and nothing else:
// unread counts, critical emphasis, history and Work in flight are unaffected.
Singleton {
  id: notices

  property var records: []
  property var banners: []
  property bool dnd: false

  // Bumped for changes that only alter a record's own content. The drawer's
  // list keeps its identity, so it does not rebuild (and cannot swallow a click
  // that is already half way through) when a notification updates itself.
  property int revision: 0

  // Transient notifications show a banner and are never archived.
  readonly property var savedRecords: {
    const result = [];
    for (let i = 0; i < notices.records.length; i++) {
      if (!notices.records[i].transient)
        result.push(notices.records[i]);
    }
    return result;
  }

  readonly property int savedCount: notices.savedRecords.length

  readonly property var bannerRecords: {
    const result = [];
    for (let i = 0; i < notices.banners.length; i++) {
      const record = notices.findById(notices.banners[i]);
      if (record)
        result.push(record);
    }
    return result;
  }

  // Banners follow the output the notification arrived on, with the focused
  // output as the fallback.
  readonly property var bannerScreen: {
    const list = notices.bannerRecords;
    for (let i = 0; i < list.length; i++) {
      const screens = Quickshell.screens;
      for (let j = 0; j < screens.length; j++) {
        if (screens[j] && screens[j].name === list[i].bannerScreen)
          return screens[j];
      }
    }
    return Desktop.focusedScreen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
  }

  readonly property int unreadCount: notices.revision >= 0 ? notices.countUnread() : 0

  function countUnread() {
    let count = 0;
    const list = notices.savedRecords;
    for (let i = 0; i < list.length; i++) {
      if (!list[i].isRead)
        count++;
    }
    return count;
  }

  readonly property bool hasUnreadCritical: notices.revision >= 0 ? notices.hasCriticalUnread() : false

  function hasCriticalUnread() {
    const list = notices.savedRecords;
    for (let i = 0; i < list.length; i++) {
      if (!list[i].isRead && list[i].urgency === NotificationUrgency.Critical)
        return true;
    }
    return false;
  }

  NotificationServer {
    keepOnReload: true
    bodySupported: true
    actionsSupported: true
    bodyMarkupSupported: false
    bodyHyperlinksSupported: false
    bodyImagesSupported: false
    actionIconsSupported: false
    imageSupported: false
    inlineReplySupported: false
    persistenceSupported: false

    onNotification: function(notification) {
      notices.receive(notification);
    }
  }

  function findById(id) {
    for (let i = 0; i < notices.records.length; i++) {
      if (notices.records[i].id === id)
        return notices.records[i];
    }
    return null;
  }

  function currentScreenName() {
    return Desktop.focusedScreen ? Desktop.focusedScreen.name : "";
  }

  function receive(notification) {
    // Take ownership so the server keeps the live object and its actions, even
    // for a transient notification that never reaches the history.
    notification.tracked = true;

    let record = notices.findById(notification.id);
    if (record) {
      record.live = notification;
      record.transient = notification.transient;
      record.expired = false;
      notices.watch(record, notification);
      notices.scheduleBanner(record);
      notices.bump();
      return;
    }

    record = {
      "id": notification.id,
      "appName": notification.appName,
      "appIcon": notification.appIcon,
      "summary": notification.summary,
      "body": String(notification.body || "").slice(0, 4096),
      "urgency": notification.urgency,
      "transient": notification.transient,
      "isRead": notification.lastGeneration === true,
      "expired": false,
      "live": notification,
      "timeMs": Date.now(),
      "bannerScreen": notices.currentScreenName(),
      "bannerDeadline": 0,
      "watched": null
    };

    notices.watch(record, notification);
    notices.records = [record].concat(notices.records);
    notices.trim();
    // Notifications carried across a hot reload are already visible context,
    // not new arrivals; do not replay their banners.
    if (notification.lastGeneration !== true)
      notices.scheduleBanner(record);
    notices.touch();
  }

  function watch(record, notification) {
    if (record.watched === notification)
      return;
    record.watched = notification;

    notification.summaryChanged.connect(function() {
      notices.bump();
    });
    notification.bodyChanged.connect(function() {
      notices.bump();
    });
    notification.appNameChanged.connect(function() {
      notices.bump();
    });
    notification.urgencyChanged.connect(function() {
      notices.bump();
    });
    notification.actionsChanged.connect(function() {
      notices.bump();
    });
    notification.closed.connect(function(reason) {
      notices.handleClosed(record, reason);
    });
  }

  function handleClosed(record, reason) {
    record.live = null;
    record.watched = null;
    record.expired = reason === NotificationCloseReason.Expired;
    notices.removeBanner(record.id);
    if (record.transient)
      notices.forget(record.id);
    notices.bump();
  }

  // Structural change: the drawer's list has to rebuild.
  function touch() {
    notices.records = notices.records.slice();
  }

  // Content change: keep the list, only tell the rows to re-read.
  function bump() {
    notices.revision = notices.revision + 1;
  }

  function trim() {
    let kept = 0;
    const keptRecords = [];
    const dropped = [];
    for (let i = 0; i < notices.records.length; i++) {
      const record = notices.records[i];
      if (kept < 100) {
        keptRecords.push(record);
        kept++;
      } else {
        dropped.push(record.id);
        if (record.live)
          record.live.dismiss();
      }
    }
    notices.records = keptRecords;
    if (dropped.length > 0) {
      notices.banners = notices.banners.filter(function(id) {
        return dropped.indexOf(id) === -1;
      });
    }
  }

  // D-Bus expire_timeout is milliseconds. -1 means server default, 0 means
  // never. Critical notifications stay until the user acts on them.
  function bannerTimeout(notification) {
    if (notification.urgency === NotificationUrgency.Critical)
      return 0;
    if (notification.expireTimeout > 0)
      return notification.expireTimeout;
    if (notification.expireTimeout === 0)
      return 0;
    return 7000;
  }

  // Do Not Disturb pauses banners; a critical notification still appears.
  function scheduleBanner(record) {
    if (!record.live)
      return;
    if (notices.dnd && record.live.urgency !== NotificationUrgency.Critical)
      return;

    const timeout = notices.bannerTimeout(record.live);
    record.bannerDeadline = timeout > 0 ? Date.now() + timeout : 0;

    const next = [record.id];
    for (let i = 0; i < notices.banners.length; i++) {
      if (notices.banners[i] !== record.id && next.length < 3)
        next.push(notices.banners[i]);
    }
    notices.banners = next;
  }

  function removeBanner(id) {
    notices.banners = notices.banners.filter(function(value) {
      return value !== id;
    });
  }

  // Marking read works on the stored record, never on the copy a row or banner
  // is holding, so it always goes through the id.
  function markRead(id) {
    const record = notices.findById(id);
    if (record)
      record.isRead = true;
    notices.bump();
  }

  // Closing a banner is not dismissing the notification: for a transient one
  // the record has nothing left to show, so it goes away with the banner.
  // Either way the user has seen it, so the banner counts as reading it.
  function hideBanner(id) {
    notices.removeBanner(id);
    const record = notices.findById(id);
    notices.markRead(id);
    if (record && record.transient) {
      if (record.live)
        record.live.dismiss();
      else
        notices.forget(id);
    }
  }

  function expireBanners() {
    const now = Date.now();
    const list = notices.banners.slice();
    for (let i = 0; i < list.length; i++) {
      const record = notices.findById(list[i]);
      if (!record)
        continue;
      if (record.bannerDeadline > 0 && now >= record.bannerDeadline) {
        record.bannerDeadline = 0;
        if (record.live)
          record.live.expire();
        else
          notices.removeBanner(record.id);
      }
    }
  }

  function markAllRead() {
    const list = notices.savedRecords;
    for (let i = 0; i < list.length; i++)
      list[i].isRead = true;
    notices.bump();
  }

  function invoke(record, identifier) {
    if (!record.live)
      return false;
    const actions = record.live.actions;
    for (let i = 0; i < actions.length; i++) {
      if (actions[i].identifier === identifier) {
        actions[i].invoke();
        // Acting on an action button is engagement: the notification is read,
        // and its banner (if any) has done its job.
        notices.markRead(record.id);
        notices.removeBanner(record.id);
        return true;
      }
    }
    return false;
  }

  // Clicking a notification behaves like the freedesktop default action:
  // invoke the main action when one exists, then dismiss the entry.
  function activate(record) {
    const live = record.live;
    let action = null;
    if (live) {
      const actions = live.actions;
      for (let i = 0; i < actions.length; i++) {
        if (actions[i].identifier === "default") {
          action = actions[i];
          break;
        }
      }
      if (!action && actions.length > 0)
        action = actions[0];
    }

    // Acting on the body reads the notification and takes it out of the
    // column, both for the row and for its banner.
    notices.markRead(record.id);
    notices.forget(record.id);

    if (action)
      action.invoke();
    else if (live)
      live.dismiss();
  }

  function forget(id) {
    // Records reach the drawer as copies (a `var` property hands out copies of
    // its maps), so identity comparison never matches here: match on the
    // notification id instead.
    notices.records = notices.records.filter(function(item) {
      return item.id !== id;
    });
    notices.removeBanner(id);
  }

  function dismiss(record) {
    notices.forget(record.id);
    if (record.live)
      record.live.dismiss();
    notices.touch();
  }

  function clearAll() {
    const list = notices.records.slice();
    notices.records = [];
    notices.banners = [];
    for (let i = 0; i < list.length; i++) {
      if (list[i].live)
        list[i].live.dismiss();
    }
    notices.touch();
  }

  function relativeTime(timeMs) {
    const seconds = Math.max(0, Math.round((Date.now() - timeMs) / 1000));
    if (seconds < 45)
      return "Just now";
    const minutes = Math.round(seconds / 60);
    if (minutes < 60)
      return minutes + " min";
    const hours = Math.round(minutes / 60);
    if (hours < 24)
      return hours + " h";
    return Math.round(hours / 24) + " d";
  }

  Timer {
    interval: 500
    repeat: true
    running: notices.banners.length > 0
    onTriggered: notices.expireBanners()
  }
}
