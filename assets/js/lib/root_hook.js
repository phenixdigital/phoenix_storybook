export const syncRootColorMode = (mode) => {
  const root = document.documentElement;

  if (!("psbColorMode" in root.dataset) || !mode) return;

  root.classList.toggle("psb:dark", mode === "dark");
};

const syncRootThemeClass = (currentClass) => {
  const root = document.documentElement;
  const previousClass = root.dataset.psbRootThemeClass;

  if (previousClass && previousClass !== currentClass) {
    root.classList.remove(previousClass);
  }

  if (currentClass) {
    root.classList.add(currentClass);
    root.dataset.psbRootThemeClass = currentClass;
  } else {
    delete root.dataset.psbRootThemeClass;
  }
};

export const RootHook = {
  mounted() {
    this.syncRootClasses();
  },

  updated() {
    this.syncRootClasses();
  },

  syncRootClasses() {
    syncRootThemeClass(this.el.dataset.psbRootThemeClass);
    syncRootColorMode(this.el.dataset.psbColorMode);
  },
};
