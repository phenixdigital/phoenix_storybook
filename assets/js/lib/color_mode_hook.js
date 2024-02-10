export const ColorModeHook = {
  mounted() {
    console.log("mounted");
    window.addEventListener("phx:set-color-mode", onSetColorMode);
    window.addEventListener("phx:page-loading-stop", onPhxNavigation);

    window
      .matchMedia("(prefers-color-scheme: dark)")
      .addEventListener("change", (event) => {
        const mode = localStorage.getItem("psb_color_mode");
        toggleColorModeClass(mode);
      });
    const mode = localStorage.getItem("psb_color_mode");
    toggleColorModeClass(mode);
  },

  destroyed() {
    window.removeEventListener("phx:set-color-mode", onSetColorMode);
    window.removeEventListener("phx:page-loading-stop", onPhxNavigation);
  },
};

function onSetColorMode(e) {
  toggleColorModeClass(e.detail.mode);
}

function onPhxNavigation(e) {
  const mode = localStorage.getItem("psb_color_mode");
  toggleColorModeClass(mode);
}

function toggleColorModeClass(mode) {
  mode = mode || "system";
  localStorage.setItem("psb_color_mode", mode);
  const sandboxDarkClass = document.documentElement.dataset.sandboxDarkClass;

  if (
    mode === "dark" ||
    (mode == "system" &&
      window.matchMedia("(prefers-color-scheme: dark)").matches)
  ) {
    document.documentElement.classList.add("psb-dark");
    Array.from(document.getElementsByClassName("psb-sandbox")).forEach((e) => {
      console.log(e);
      e.classList.add(sandboxDarkClass);
    });
  } else {
    document.documentElement.classList.remove("psb-dark");
    Array.from(document.getElementsByClassName("psb-sandbox")).forEach((e) => {
      e.classList.remove(sandboxDarkClass);
    });
  }
}

const mode = localStorage.getItem("psb_color_mode");
toggleColorModeClass(mode);
