// Sizes the screen-size preview iframe: exact CSS width (never scaled; the pane scrolls on x),
// height following its content, and pushes the new width when the user drags the box.
const DRAG_DEBOUNCE_MS = 300;

export const ScreenSizeHook = {
  mounted() {
    this.bindPreview();
  },

  updated() {
    this.bindPreview();
  },

  destroyed() {
    this.boxResizeObserver?.disconnect();
    this.contentResizeObserver?.disconnect();
  },

  bindPreview() {
    const box = this.el.querySelector(".psb-screen-size-box");
    if (box !== this.box) {
      this.box = box;
      this.contentHeightPx = 0;
      this.iframe = box.querySelector("iframe");
      this.iframe.addEventListener("load", () => this.observeIframeContent());
      this.boxResizeObserver?.disconnect();
      this.boxResizeObserver = new ResizeObserver(() => this.onBoxResized());
      this.boxResizeObserver.observe(box);
      // the iframe may have loaded during the dead render, before this hook mounted
      if (this.iframe.contentDocument?.readyState === "complete") this.observeIframeContent();
    }
    this.layout();
  },

  observeIframeContent() {
    const iframeWindow = this.iframe.contentWindow;
    this.contentResizeObserver?.disconnect();
    // observer built from the iframe's own window, so it watches the iframe document reliably
    this.contentResizeObserver = new iframeWindow.ResizeObserver(() => {
      // body, not documentElement: the latter never reports less than the iframe's own height
      const body = iframeWindow.document.body;
      this.contentHeightPx = Math.ceil(
        body.getBoundingClientRect().height +
          Number.parseFloat(iframeWindow.getComputedStyle(body).marginTop) +
          Number.parseFloat(iframeWindow.getComputedStyle(body).marginBottom),
      );
      this.layout();
    });
    this.contentResizeObserver.observe(iframeWindow.document.body);
  },

  layout() {
    if (!this.box) return;
    const screenWidthPx = Number(this.el.dataset.screenWidth);
    const contentHeightPx = this.contentHeightPx || 0;

    this.iframe.style.width = `${screenWidthPx}px`;
    this.iframe.style.height = `${contentHeightPx}px`;
    this.box.style.width = `${screenWidthPx}px`;
    this.box.style.height = `${contentHeightPx}px`;
    this.boxWidthSetByLayoutPx = this.box.clientWidth;
  },

  onBoxResized() {
    // clientWidth: the box is content-box, so this is the CSS width the iframe gets
    const boxWidthPx = this.box.clientWidth;
    if (Math.abs(boxWidthPx - this.boxWidthSetByLayoutPx) <= 1) return;
    clearTimeout(this.dragDebounceTimer);
    this.dragDebounceTimer = setTimeout(() => {
      this.pushEvent("psb-set-screen-width", { width: boxWidthPx });
    }, DRAG_DEBOUNCE_MS);
  },
};
