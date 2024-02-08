export const ColorModeHook = {
  mounted() {
    window.addEventListener("phx:set-color-mode", (e) => {
      toggleColorModeClass(e.detail.mode);
    });
    const mode = localStorage.getItem("psb_color_mode");
    toggleColorModeClass(mode);
  },
};

function toggleColorModeClass(mode) {
  mode = mode || "system";
  localStorage.setItem("psb_color_mode", mode);
  if (
    mode === "dark" ||
    (mode == "system" &&
      window.matchMedia("(prefers-color-scheme: dark)").matches)
  ) {
    document.documentElement.classList.add("dark");
  } else {
    document.documentElement.classList.remove("dark");
  }
}
