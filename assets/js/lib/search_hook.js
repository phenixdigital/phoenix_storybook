export const SearchHook = {
   mounted() {
      const searchContainer = document.querySelector("#search-container");
      const searchList = document.querySelector("#search-list");
      const searchInput = document.querySelector("#search-container input");
      const allEntries = document.querySelector("#search-list").children
      const firstEntry = document.querySelector("#search-list").firstElementChild
      const lastEntry = document.querySelector("#search-list").lastElementChild
      let activeEntry = firstEntry

      window.addEventListener('keydown', (e) => {
         if(e.metaKey && (e.key === 'k' || e.key === 'K')){
            this.liveSocket.execJS(searchContainer, searchContainer.getAttribute("phx-show"))
            searchInput.focus();

            activeEntry.classList.add("lsb-bg-indigo-600", "lsb-text-white");
         }
      });

      [...allEntries].forEach(entry => {
         entry.addEventListener('mouseover', (e) => {
            if (e.movementX != 0 && e.movementY != 0){
               activeEntry.classList.remove("lsb-bg-indigo-600", "lsb-text-white");
               activeEntry = e.target
               activeEntry.classList.add("lsb-bg-indigo-600", "lsb-text-white");
            }
         })
      }); 

      searchContainer.addEventListener('keydown', (e) => {
         if(e.key === 'Enter'){
            e.preventDefault();
            const link = activeEntry.firstElementChild

            this.pushEventTo("#search-container", "navigate", {path: link.pathname});
            this.liveSocket.execJS(searchContainer, searchContainer.getAttribute("phx-hide"))
         }

         if(e.key === 'Escape'){
            this.liveSocket.execJS(searchContainer, searchContainer.getAttribute("phx-hide"))
         }

         if(e.key === 'Tab'){
            // This prevents the use of tab within the search modal 
            // to keep the focus in the search input.
            e.preventDefault();
         }

         if(e.key === 'ArrowUp'){
            activeEntry.classList.remove("lsb-bg-indigo-600", "lsb-text-white");

            if (activeEntry == firstEntry){
               activeEntry = lastEntry
            } else {
               activeEntry = activeEntry.previousElementSibling;
            }

            activeEntry.classList.add("lsb-bg-indigo-600", "lsb-text-white");
            activeEntry.scrollIntoView({block: "nearest", inline: "nearest"})
         }

         if(e.key === 'ArrowDown'){
            activeEntry.classList.remove("lsb-bg-indigo-600", "lsb-text-white");

            if (activeEntry == lastEntry){
               activeEntry = firstEntry
            } else {
               activeEntry = activeEntry.nextElementSibling;
            }

            activeEntry.classList.add("lsb-bg-indigo-600", "lsb-text-white");
            activeEntry.scrollIntoView({block: "nearest", inline: "nearest"})
         }
      })

      searchList.addEventListener('click', (e) => {
         const link = activeEntry.firstElementChild

         this.pushEventTo("#search-container", "navigate", {path: link.pathname});
         this.liveSocket.execJS(searchContainer, searchContainer.getAttribute("phx-hide"))
      })
   }

 };
 