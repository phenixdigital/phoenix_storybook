export const SearchHook = {
   mounted() {
      const searchContainer = document.querySelector("#search-container");
      const searchList = document.querySelector("#search-list");
      const searchInput = document.querySelector("#search-container input");

      window.addEventListener('keydown', (e) => {
         if(e.key === 'Enter'){
            if (e.target == document.activeElement) {
               const link = e.target.children[0]
               this.pushEventTo("#search-container", "navigate", {path: link.pathname});

               this.liveSocket.execJS(searchContainer, searchContainer.getAttribute("phx-hide"))
            }
         }

         if(e.metaKey && e.key === 'k'){
            this.liveSocket.execJS(searchContainer, searchContainer.getAttribute("phx-show"))
            searchInput.focus();
         }

         if(e.key === 'Escape'){
            this.liveSocket.execJS(searchContainer, searchContainer.getAttribute("phx-hide"))
         }
      });

      searchList.addEventListener('click', (e) => {
         this.liveSocket.execJS(searchContainer, searchContainer.getAttribute("phx-hide"))
      })
}
 };
 