export const SidebarHook = {
  mounted() {
    const sidebarContainer = document.querySelector("#sidebar-container");
    const overlay = document.querySelector("#sidebar-overlay");

    const openSidebar = () => {
      sidebarContainer.classList.remove("lsb-hidden");
      overlay.classList.remove("lsb-hidden");
    };

    const closeSidebar = () => {
      sidebarContainer.classList.add("lsb-hidden");
      overlay.classList.add("lsb-hidden");
    };

    this.handleEvent("lsb:open-sidebar", openSidebar);
    this.handleEvent("lsb:close-sidebar", closeSidebar);

    window.addEventListener("lsb:open-sidebar", openSidebar);
    window.addEventListener("lsb:close-sidebar", closeSidebar);
  },
};
