import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { ColorModeHook } from "./lib/color_mode_hook";
import { SearchHook } from "./lib/search_hook";
import { SidebarHook } from "./lib/sidebar_hook";
import { StoryHook } from "./lib/story_hook";

if (window.storybook === undefined) {
  console.warn("No storybook configuration detected.");
  console.warn(
    "If you need to use custom hooks or uploaders, please define them in JS file and declare this \
    file in your Elixir backend module options (:js_path key).",
  );
  window.storybook = {};
}

const socketPath = document.querySelector("html").getAttribute("phx-socket") || "/live";

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");

const selectedColorMode = ColorModeHook.selectedColorMode();
const actualColorMode = ColorModeHook.actualColorMode(selectedColorMode);

const liveSocket = new LiveSocket(socketPath, Socket, {
  hooks: {
    ...window.storybook.Hooks,
    StoryHook,
    SearchHook,
    SidebarHook,
    ColorModeHook,
  },
  uploaders: window.storybook.Uploaders,
  params: (_liveViewName) => {
    return {
      _csrf_token: csrfToken,
      extra: window.storybook.Params,
      selected_color_mode: selectedColorMode,
      color_mode: actualColorMode,
    };
  },
  ...window.storybook.LiveSocketOptions,
});

liveSocket.connect();
window.liveSocket = liveSocket;
