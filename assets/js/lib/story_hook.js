export const StoryHook = {
  mounted() {
    // scrolling to matching anchor if present in location hash
    if (window.location.hash) {
      const el = document.querySelector(window.location.hash);
      if (el) {
        const liveContainer = document.querySelector("#live-container");
        setTimeout(() => {
          liveContainer.scrollTop = el.offsetTop - 115;
        }, 100);
      }
    }

    this.bindAnchorLinks();
    this.bindCopyCodeLinks();
  },

  updated() {
    this.bindAnchorLinks();
  },
  bindAnchorLinks() {
    for (const link of document.querySelectorAll(".variation-anchor-link")) {
      link.addEventListener("click", (event) => {
        event.preventDefault();
        window.history.replaceState({}, "", link.hash);
      });
    }
  },
  bindCopyCodeLinks() {
    const buttonClasses = ["psb:text-slate-500", "psb:hover:text-slate-100"];
    const buttonActiveClasses = ["psb:text-green-400", "psb:hover:text-green-400"];
    const iconClass = "fa-copy";
    const iconActiveClass = "fa-check";

    window.addEventListener("psb:copy-code", (e) => {
      const button = e.target;
      const icon = button.querySelector(".svg-inline--fa") || button.querySelector(".fa-copy");
      button.classList.add(...buttonActiveClasses);
      button.classList.remove(...buttonClasses);
      icon.classList.add(iconActiveClass);
      icon.classList.remove(iconClass);

      this.copyToClipboard(button.nextElementSibling.textContent);

      setTimeout(() => {
        const icon = button.querySelector(".svg-inline--fa") || button.querySelector(".fa-copy");
        icon.classList.add(iconClass);
        icon.classList.remove(iconActiveClass);
        button.classList.add(...buttonClasses);
        button.classList.remove(...buttonActiveClasses);
      }, 1000);
    });
  },
  copyToClipboard(text) {
    const textarea = document.createElement("textarea");
    textarea.textContent = text;
    textarea.style.position = "fixed"; // Prevent scrolling to bottom of page in Microsoft Edge.
    document.body.appendChild(textarea);
    textarea.select();
    try {
      return document.execCommand("copy"); // Security exception may be thrown by some browsers.
    } catch (ex) {
      console.warn("Copy to clipboard failed.", ex);
      return prompt("Copy to clipboard: Ctrl+C, Enter", text);
    } finally {
      document.body.removeChild(textarea);
    }
  },
};
