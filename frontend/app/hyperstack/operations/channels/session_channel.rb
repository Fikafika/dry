# backtick_javascript: true

return unless RUBY_ENGINE == 'opal'

%x{
ApiCable.subscriptions.create("SessionChannel", {
  received: function (data) {
    for (k in data) {
      switch (k) {
        case "session_id_changed":
          this._sessionIdChanged(data[k]);
          break;
        case "current_user":
          this._refreshCurrentUser(data[k]);
          break;
        case "destroyed":
          this._destroyed(data[k]);
          break;
      }
    }
  },

  _sessionIdChanged(data) {
    this._reopenCable();
    this._trigger("sessionIdChanged", data);
  },

  _refreshCurrentUser(data) {
    if (data && data["attributes"] && data["attributes"]["id"]) {
      // new current user
      this._registerTrigger("sessionIdChanged", () => { #{User.current(true)} });
    } else {
      // no current user
      if (!data || !data["pending_uneek_sso_sign_out"]) {
        #{User.current.refresh({})}
      }
    }
  },

  _destroyed() {
    this._refresh();
    this._reopenCable();
  },

  _refresh() {
    this._refreshCurrentUser();
  },

  _reopenCable() {
    ApiCable.connection.cleanReopen().catch((e) => { this._refresh() });
    // TODO hyperstack cable channel identifier is also the session id, maybe we should reopen it?
  },

  _trigger(event, data) {
    if (!this._triggers || !this._triggers[event])
      return;
    while (this._triggers[event][0]) {
      this._triggers[event].shift().call(this, data);
    }
  },

  _registerTrigger(event, action) {
    this._triggers = this._triggers || {};
    this._triggers[event] = this._triggers[event] || [];
    this._triggers[event].push(action);
  }
});
}
