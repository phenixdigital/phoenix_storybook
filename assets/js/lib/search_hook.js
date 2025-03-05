export const SearchHook = {
  mounted() {
    const searchContainer = document.querySelector("#search-container");
    const searchModal = document.querySelector("#search-modal");
    const searchList = document.querySelector("#search-list");
    const searchInput = document.querySelector("#search-input");

    let allStories = searchList.children;
    let firstStory = searchList.firstElementChild;
    let lastStory = searchList.lastElementChild;
    let activeStory = firstStory;

    const observer = new MutationObserver((mutations) => {
      allStories = searchList.children;
      firstStory = searchList.firstElementChild;
      lastStory = searchList.lastElementChild;

      if (allStories.length > 0) {
        this.liveSocket.execJS(activeStory, activeStory.getAttribute("phx-baseline"));
        activeStory = firstStory;
        this.liveSocket.execJS(activeStory, activeStory.getAttribute("phx-highlight"));
      }
    });

    observer.observe(searchList, {
      childList: true,
    });

    window.addEventListener("psb:open-search", () => {
      this.liveSocket.execJS(searchContainer, searchContainer.getAttribute("phx-show"));
      this.liveSocket.execJS(searchModal, searchModal.getAttribute("phx-show"));
      setTimeout(() => searchInput.focus(), 50);
      this.liveSocket.execJS(activeStory, activeStory.getAttribute("phx-highlight"));
    });

    window.addEventListener("psb:close-search", () => {
      this.liveSocket.execJS(searchModal, searchModal.getAttribute("phx-hide"));
      this.liveSocket.execJS(searchContainer, searchContainer.getAttribute("phx-hide"));
    });

    window.addEventListener("keydown", (e) => {
      if (e.metaKey && (e.key === "k" || e.key === "K")) {
        e.preventDefault();
        this.dispatchOpenSearch();
      }
    });

    for (const story of allStories) {
      story.addEventListener("mouseover", (e) => {
        if (e.movementX !== 0 && e.movementY !== 0 && e.target === story) {
          // This prevents clipping when switching back and forth
          // between mouse navigation and keyboard navigation

          this.liveSocket.execJS(activeStory, activeStory.getAttribute("phx-baseline"));
          activeStory = e.target;
          this.liveSocket.execJS(activeStory, activeStory.getAttribute("phx-highlight"));
        }
      });
    }

    searchContainer.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        const link = activeStory.firstElementChild;

        this.resetInput(searchInput);
        this.pushEventTo("#search-container", "navigate", {
          path: link.pathname,
        });
        this.dispatchCloseSearch();
      }

      if (e.key === "Escape") {
        this.dispatchCloseSearch();
      }

      if (e.key === "Tab") {
        // This prevents the use of tab within the search modal
        // to keep the focus in the search input.
        e.preventDefault();
      }

      if (e.key === "ArrowUp") {
        this.liveSocket.execJS(activeStory, activeStory.getAttribute("phx-baseline"));

        if (activeStory === firstStory) {
          activeStory = lastStory;
        } else {
          activeStory = activeStory.previousElementSibling;
        }

        this.liveSocket.execJS(activeStory, activeStory.getAttribute("phx-highlight"));
        activeStory.scrollIntoView({ block: "nearest", inline: "nearest" });
      }

      if (e.key === "ArrowDown") {
        this.liveSocket.execJS(activeStory, activeStory.getAttribute("phx-baseline"));

        if (activeStory === lastStory) {
          activeStory = firstStory;
        } else {
          activeStory = activeStory.nextElementSibling;
        }

        this.liveSocket.execJS(activeStory, activeStory.getAttribute("phx-highlight"));
        activeStory.scrollIntoView({ block: "nearest", inline: "nearest" });
      }
    });

    searchList.addEventListener("click", (e) => {
      const link = activeStory.firstElementChild;

      this.resetInput(searchInput);
      this.pushEventTo("#search-container", "navigate", {
        path: link.pathname,
      });
      this.dispatchCloseSearch();
    });
  },

  resetInput(searchInput) {
    searchInput.value = "";
    this.pushEventTo("#search-container", "search", { search: { input: "" } });
  },

  dispatchOpenSearch() {
    const event = new Event("psb:open-search");
    window.dispatchEvent(event);
  },

  dispatchCloseSearch() {
    const event = new Event("psb:close-search");
    window.dispatchEvent(event);
  },
};
