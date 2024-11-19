export const ColorModeHook = {
  mounted() {
    window.addEventListener("psb:set-color-mode", onSetColorMode);

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
    window.removeEventListener("psb:set-color-mode", onSetColorMode);
  },
};

function onSetColorMode(e) {
  toggleColorModeClass(e.detail.mode);
}

function toggleColorModeClass(mode) {
  mode = mode || "system";
  localStorage.setItem("psb_color_mode", mode);

  if (
    mode === "dark" ||
    (mode == "system" &&
      window.matchMedia("(prefers-color-scheme: dark)").matches)
  ) {
    document.documentElement.classList.add("psb-dark");
  } else {
    document.documentElement.classList.remove("psb-dark");
  }
}

const mode = localStorage.getItem("psb_color_mode");
toggleColorModeClass(mode);
