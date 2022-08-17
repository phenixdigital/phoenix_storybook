import { LiveSocket } from "phoenix_live_view";
import { Socket } from "phoenix";

if (window.storybook === undefined) {
  console.warn("No storybook configuration detected.");
  console.warn(
    "If you need to use custom hooks or uploaders, please define them in JS file\
  and declare this file in your Elixir app config (:js_path key) "
  );
  window.storybook = {};
}

let socketPath =
  document.querySelector("html").getAttribute("phx-socket") || "/live";

let csrfToken = window.parent.document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

console.log("csrfToken", csrfToken);

let liveSocket = new LiveSocket(socketPath, Socket, {
  hooks: { ...window.storybook.Hooks },
  uploaders: window.storybook.Uploaders,
  params: (liveViewName) => {
    return {
      _csrf_token: csrfToken,
    };
  },
});

liveSocket.connect();

window.liveSocket = liveSocket;
