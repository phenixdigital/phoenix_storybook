// Every animation class is `max-lg:`-scoped so it only takes effect below the
// `lg` breakpoint. `open`/`close` run on desktop too — the server pushes
// `psb:close-sidebar` on navigation regardless of viewport — but there the
// sidebar is a permanently visible column, not a drawer. Scoping the classes to
// mobile makes those calls inert on desktop; otherwise `close` would run the
// exit animation and slide the always-visible desktop sidebar off screen.

const SIDEBAR_IN = ["psb:max-lg:motion-translate-x-in-[-100%]"];
const SIDEBAR_OUT = ["psb:max-lg:motion-translate-x-out-[-100%]"];
const OVERLAY_IN = ["psb:max-lg:motion-opacity-in-0"];
const OVERLAY_OUT = ["psb:max-lg:motion-opacity-out-0"];

export const SidebarHook = {
  mounted() {
    const container = document.querySelector("#psb-sidebar-container");
    const overlay = document.querySelector("#psb-sidebar-overlay");
    const sidebar = this.el;
    let closeTimer;

    const openSidebar = () => {
      clearTimeout(closeTimer);
      sidebar.classList.remove(...SIDEBAR_OUT);
      overlay.classList.remove(...OVERLAY_OUT);
      container.classList.remove("psb:hidden");
      overlay.classList.remove("psb:hidden");
      sidebar.classList.add(...SIDEBAR_IN);
      overlay.classList.add(...OVERLAY_IN);
    };

    const closeSidebar = () => {
      sidebar.classList.remove(...SIDEBAR_IN);
      overlay.classList.remove(...OVERLAY_IN);
      sidebar.classList.add(...SIDEBAR_OUT);
      overlay.classList.add(...OVERLAY_OUT);
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
