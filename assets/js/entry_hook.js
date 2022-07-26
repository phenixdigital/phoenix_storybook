export const EntryHook = {
  mounted() {
    // scrolling to matching anchor if present in location hash
    if (window.location.hash) {
      const el = document.querySelector(window.location.hash);
      if (el) {
        const liveContainer = document.querySelector("#live-container");
        setTimeout(() => {
          liveContainer.scrollTop = el.offsetTop - 10;
        }, 100);
      }
    }

    this.bindAnchorLinks();
  },

  updated() {
    this.bindAnchorLinks();
  },
  bindAnchorLinks() {
    document.querySelectorAll(".entry-anchor-link").forEach((link) => {
      link.addEventListener("click", (event) => {
        event.preventDefault();
        window.history.replaceState({}, "", link.hash);
      });
    });
  },
};
