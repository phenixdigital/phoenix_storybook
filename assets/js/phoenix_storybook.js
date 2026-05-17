// phoenix and phoenix_live_view are loaded from host app dependencies (see JSAssets module)
import { ColorModeHook } from "./lib/color_mode_hook";
import { SearchHook } from "./lib/search_hook";
import { SidebarHook } from "./lib/sidebar_hook";
import { StoryHook } from "./lib/story_hook";
import { warnReservedHooks } from "./lib/warn_reserved_hooks";

if (window.storybook === undefined) {
  console.warn("No storybook configuration detected.");
  console.warn(
    "If you need to use custom hooks or uploaders, please define them in JS file and declare this \
    file in your Elixir backend module options (:js_path key).",
  );
  window.storybook = {};
}

const LiveView = window.storybook?.LiveView || window.LiveView;
const Phoenix = window.storybook?.Phoenix || window.Phoenix;
const socketPath = document.querySelector("html").getAttribute("phx-socket") || "/live";

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");

const selectedColorMode = ColorModeHook.selectedColorMode();
const actualColorMode = ColorModeHook.actualColorMode(selectedColorMode);

const psbHooks = {
  "PhoenixStorybook.StoryHook": StoryHook,
  "PhoenixStorybook.SearchHook": SearchHook,
  "PhoenixStorybook.SidebarHook": SidebarHook,
  "PhoenixStorybook.ColorModeHook": ColorModeHook,
};
warnReservedHooks(Object.keys(psbHooks), window.storybook.Hooks);

const liveSocket = new LiveView.LiveSocket(socketPath, Phoenix.Socket, {
  hooks: { ...window.storybook.Hooks, ...psbHooks },
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
