export const SearchHook = {
   mounted() {
      const searchContainer = document.querySelector("#search-container");
      const searchList = document.querySelector("#search-list");
      const searchInput = document.querySelector("#search-container input");
      let allEntries = searchList.children
      let firstEntry = searchList.firstElementChild
      let lastEntry = searchList.lastElementChild
      let activeEntry = firstEntry

      let observer = new MutationObserver(mutations => {
         allEntries = searchList.children
         firstEntry = searchList.firstElementChild
         lastEntry = searchList.lastElementChild

         activeEntry.classList.remove("lsb-bg-slate-50", "lsb-text-indigo-600");
         activeEntry = firstEntry
         activeEntry.classList.add("lsb-bg-slate-50", "lsb-text-indigo-600");
      });

      observer.observe(searchList, {
         childList: true
     });

      window.addEventListener('keydown', (e) => {
         if(e.metaKey && (e.key === 'k' || e.key === 'K')){
            this.liveSocket.execJS(searchContainer, searchContainer.getAttribute("phx-show"))
            searchInput.focus();

            activeEntry.classList.add("lsb-bg-slate-50", "lsb-text-indigo-600");
         }
      });

      [...allEntries].forEach(entry => {
         entry.addEventListener('mouseover', (e) => {
            if (e.movementX != 0 && e.movementY != 0){
               // This prevents clipping when switching back and forth 
               // between mouse navigation and keyboard navigation
               activeEntry.classList.remove("lsb-bg-slate-50", "lsb-text-indigo-600");
               activeEntry = e.target
               activeEntry.classList.add("lsb-bg-slate-50", "lsb-text-indigo-600");
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
            activeEntry.classList.remove("lsb-bg-slate-50", "lsb-text-indigo-600");

            if (activeEntry == firstEntry){
               activeEntry = lastEntry
            } else {
               activeEntry = activeEntry.previousElementSibling;
            }

            activeEntry.classList.add("lsb-bg-slate-50", "lsb-text-indigo-600");
            activeEntry.scrollIntoView({block: "nearest", inline: "nearest"})
         }

         if(e.key === 'ArrowDown'){
            activeEntry.classList.remove("lsb-bg-slate-50", "lsb-text-indigo-600");

            if (activeEntry == lastEntry){
               activeEntry = firstEntry
            } else {
               activeEntry = activeEntry.nextElementSibling;
            }

            activeEntry.classList.add("lsb-bg-slate-50", "lsb-text-indigo-600");
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
 