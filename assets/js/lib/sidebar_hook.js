export const SidebarHook = {
  mounted() {
    const sidebarContainer = document.querySelector("#sidebar-container");
    const overlay = document.querySelector("#sidebar-overlay");

    const openSidebar = () => {
      sidebarContainer.classList.remove("psb:hidden");
      overlay.classList.remove("psb:hidden");
    };

    const closeSidebar = () => {
      sidebarContainer.classList.add("psb:hidden");
      overlay.classList.add("psb:hidden");
    };

    this.handleEvent("psb:open-sidebar", openSidebar);
    this.handleEvent("psb:close-sidebar", closeSidebar);

    window.addEventListener("psb:open-sidebar", openSidebar);
    window.addEventListener("psb:close-sidebar", closeSidebar);
  },
};
