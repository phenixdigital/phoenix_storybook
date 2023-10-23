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

const colorModeHook = {
  mounted() {
    if (!localStorage.psb_theme) return
    const colorMode = localStorage.getItem("psb_theme")
    this.pushEvent("psb:color-mode", { "color-mode": colorMode })
  },
};

function toggleColorMode(){
  const htmlClass = document.documentElement.classList.contains('psb-dark')
  if(localStorage.psb_theme == 'dark' && !htmlClass) document.documentElement.classList.add('psb-dark')
  else if(localStorage.psb_theme == 'light' && htmlClass) document.documentElement.classList.remove('psb-dark')
}

window.addEventListener("psb:toggle-darkmode", () => {
  if(localStorage.psb_theme == 'light') localStorage.psb_theme = 'dark';
  else localStorage.psb_theme = 'light';
  toggleColorMode();
})

toggleColorMode();

let socketPath =
  document.querySelector("html").getAttribute("phx-socket") || "/live";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute("content");

let liveSocket = new LiveSocket(socketPath, Socket, {
  hooks: { ...window.storybook.Hooks, StoryHook, SearchHook, SidebarHook, colorModeHook },
  uploaders: window.storybook.Uploaders,
  params: (liveViewName) => {
    return {
      _csrf_token: csrfToken,
      extra: window.storybook.Params,
    };
  },
  ...window.storybook.LiveSocketOptions,
});

liveSocket.connect();
window.liveSocket = liveSocket;
