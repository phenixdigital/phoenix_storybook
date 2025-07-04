// import { Socket } from "phoenix";
// import { LiveSocket } from "phoenix_live_view";
import { ColorModeHook } from "./lib/color_mode_hook";

if (window.storybook === undefined) {
  console.warn("No storybook configuration detected.");
  console.warn(
    "If you need to use custom hooks or uploaders, please define them in JS file and declare this \
    file in your in your Elixir backend module options (:js_path key).",
  );
  window.storybook = {};
}

const socketPath = document.querySelector("html").getAttribute("phx-socket") || "/live";

const csrfToken = window.parent.document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute("content");

const liveSocket = new LiveView.LiveSocket(socketPath, Phoenix.Socket, {
  hooks: { ...window.storybook.Hooks, ColorModeHook },
  uploaders: window.storybook.Uploaders,
  params: (_liveViewName) => {
    return {
      _csrf_token: csrfToken,
    };
  },
  ...window.storybook.LiveSocketOptions,
});

liveSocket.connect();
window.liveSocket = liveSocket;
