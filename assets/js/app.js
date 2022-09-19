import { LiveSocket } from "phoenix_live_view";
import { Socket } from "phoenix";
import { StoryHook } from "./lib/story_hook";
import { SearchHook } from "./lib/search_hook";
import { SidebarHook } from "./lib/sidebar_hook";

if (window.storybook === undefined) {
  console.warn("No storybook configuration detected.");
  console.warn(
    "If you need to use custom hooks or uploaders, please define them in JS file and declare this \
    file in your Elixir backend module options (:js_path key)."
  );
  window.storybook = {};
}

let socketPath =
  document.querySelector("html").getAttribute("phx-socket") || "/live";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket(socketPath, Socket, {
  hooks: { ...window.storybook.Hooks, StoryHook, SearchHook, SidebarHook },
  uploaders: window.storybook.Uploaders,
  params: (liveViewName) => {
    return {
      _csrf_token: csrfToken,
    };
  },
});

liveSocket.connect();
window.liveSocket = liveSocket;
