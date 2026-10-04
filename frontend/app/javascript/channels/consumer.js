// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `rails generate channel` command.

import "./connection"
import { INTERNAL,createConsumer } from "@rails/actioncable"

export default createConsumer(`${APP_PATH_PREFIX}/api${INTERNAL.default_mount_path}`)
