import { LiveSocket } from "phoenix_live_view";
import { Socket } from "phoenix";

window.storybook ||= {};

let socketPath =
  document.querySelector("html").getAttribute("phx-socket") || "/live";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket(socketPath, Socket, {
  hooks: window.storybook.Hooks,
  uploaders: window.storybook.Uploaders,
  params: (liveViewName) => {
    return {
      _csrf_token: csrfToken,
    };
  },
});

liveSocket.connect();

window.liveSocket = liveSocket;
