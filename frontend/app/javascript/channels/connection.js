import { Connection, logger } from "@rails/actioncable"

Connection.prototype.promiseOpen = function () {
  return new Promise((resolve, reject) => {
    if (this.open.apply(this, arguments)) {
      const oldOnopen = this.webSocket.onopen
      this.webSocket.onopen = function () {
        oldOnopen.apply(this, arguments)
        resolve()
      }

      const oldOnerror = this.webSocket.onopen
      this.webSocket.onerror = function () {
        oldOnerror.apply(this, arguments)
        reject()
      }
    } else {
      resolve()
    }
  })
}

Connection.prototype.promiseClose = function () {
  return new Promise((resolve, reject) => {
    try {
      const oldOnclose = this.webSocket.onclose
      this.webSocket.onclose = function () {
        oldOnclose.apply(this, arguments)
        resolve()
      }
      this.close()
    } catch (error) {
      reject(error)
    }
  })
}

/*
 * Uses promises and re-retrieves a session id if necessary.
 */
Connection.prototype.cleanReopen = function () {
  return new Promise((resolve, reject) => {
    const open = () => {
      Opal.HTTP.$send("get", `${APP_PATH_PREFIX}/api`).$to_n().then(() => {
        this.promiseOpen().then(resolve)
      }).catch(reject)
    }

    logger.log(`Reopening WebSocket, current state is ${this.getState()}`)
    if (this.isActive()) {
      this.promiseClose({ allowReconnect: false })
      .catch((error) => {
        logger.log("Failed to reopen WebSocket", error)
      })
      .finally(() => {
        logger.log(`Reopening WebSocket in ${this.constructor.reopenDelay}ms`)
        setTimeout(open, this.constructor.reopenDelay)
      });
    } else {
      open()
    }
  })
}
