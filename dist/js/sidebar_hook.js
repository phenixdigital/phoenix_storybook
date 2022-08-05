(() => {
  // js/sidebar_hook.js
  var SidebarHook = {
    mounted() {
      let sidebar = document.querySelector("#sidebar");
      let overlay = document.querySelector("#sidebar-overlay");
      this.handleEvent("close-sidebar", (_data) => {
        sidebar.classList.add("lsb-hidden");
        overlay.classList.add("lsb-hidden");
      });
    }
  };
})();
