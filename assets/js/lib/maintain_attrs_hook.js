// Helps to maintain element attributes when the element is updated on the server side.
// Useful for maintaining textarea size after user resizes it.
// Based on https://github.com/phoenixframework/phoenix_live_view/issues/1011#issuecomment-649157840
export const MaintainAttrsHook = {
    attrs() {
        return this.el.getAttribute("data-attrs").split(", ")
    },
    beforeUpdate() {
        this.prevAttrs = this.attrs().map(name => [name, this.el.getAttribute(name)])
    },
    updated() {
        this.prevAttrs.forEach(([name, val]) => this.el.setAttribute(name, val))
    }
}
