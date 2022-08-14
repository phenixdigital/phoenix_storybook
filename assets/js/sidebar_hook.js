export const SidebarHook = {
  mounted() {
    let sidebar = document.querySelector("#sidebar");
    let overlay = document.querySelector("#sidebar-overlay");

    this.handleEvent("lsb:open-sidebar", (_data) => {
      sidebar.classList.remove("lsb-hidden");
      overlay.classList.remove("lsb-hidden");
    });

    this.handleEvent("lsb:close-sidebar", (_data) => {
      sidebar.classList.add("lsb-hidden");
      overlay.classList.add("lsb-hidden");
    });
  },
};
