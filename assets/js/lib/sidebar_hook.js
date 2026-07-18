// The mobile sidebar is a drawer: the container/overlay toggle `psb:hidden`, the
// panel slides in via a transform transition, and the overlay fades via an
// opacity transition. Every animation utility is `max-lg:`-scoped so it only
// applies below the `lg` breakpoint. `open`/`close` run on desktop too — the
// server pushes `psb:close-sidebar` on navigation regardless of viewport — but
// there the sidebar is a permanently visible column, so the scoped classes are
// inert and can't slide the always-visible desktop sidebar off screen.

const SIDEBAR_CLOSED = ["psb:max-lg:-translate-x-full"];
const OVERLAY_CLOSED = ["psb:max-lg:opacity-0"];

export const SidebarHook = {
  mounted() {
    const container = document.querySelector("#psb-sidebar-container");
    const overlay = document.querySelector("#psb-sidebar-overlay");
    const sidebar = this.el;
    let closeTimer;

    const openSidebar = () => {
      clearTimeout(closeTimer);
      container.classList.remove("psb:hidden");
      overlay.classList.remove("psb:hidden");
      // Force a reflow so the browser paints the closed state before we move to
      // the open state — otherwise the display:none → block change and the class
      // removal collapse into one frame and the slide-in is skipped.
      void sidebar.offsetWidth;
      sidebar.classList.remove(...SIDEBAR_CLOSED);
      overlay.classList.remove(...OVERLAY_CLOSED);
    };

    const closeSidebar = () => {
      sidebar.classList.add(...SIDEBAR_CLOSED);
      overlay.classList.add(...OVERLAY_CLOSED);
      closeTimer = setTimeout(() => {
        container.classList.add("psb:hidden");
        overlay.classList.add("psb:hidden");
      }, 300);
    };

    this.handleEvent("psb:open-sidebar", openSidebar);
    this.handleEvent("psb:close-sidebar", closeSidebar);

    window.addEventListener("psb:open-sidebar", openSidebar);
    window.addEventListener("psb:close-sidebar", closeSidebar);
  },
};
