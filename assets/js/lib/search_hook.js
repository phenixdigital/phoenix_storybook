export const SearchHook = {
   mounted() {
      const searchContainer = document.querySelector("#search-container");

      window.addEventListener('keydown', (e) => {
         if(e.key === 'Enter'){
            if (e.target == document.activeElement) {
               const link = e.target.children[0]
               this.pushEventTo("#search-container", "navigate", {path: link.pathname});

               searchContainer.classList.add("lsb-ease-in");
               searchContainer.classList.add("lsb-hidden");
            }
         }

         if(e.metaKey && e.key === 'k'){
            searchContainer.classList.add("lsb-ease-out");
            searchContainer.classList.remove("lsb-hidden");
         }

         if(e.key === 'Escape'){
            searchContainer.classList.add("lsb-ease-in");
            searchContainer.classList.add("lsb-hidden");
         }
      });

      searchContainer.addEventListener('click', (e) => {
         searchContainer.classList.add("lsb-ease-in");
         searchContainer.classList.add("lsb-hidden");
      })
}
 };
 