module.exports = {
  content: [
    "./css/**/*.css",
    "./js/**/*.js",
    "../lib/**/*.{ex,heex}",
    "../priv/templates/**/*.eex",
  ],
  safelist: [
    { pattern: /^\!?psb-(w|h|m|p)\w?-.+/ },
    {
      pattern:
        /^psb-text-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)(-\d\d\d?)?$/,
    },
  ],
  theme: {
    fontFamily: {
      mono: ["Menlo", "Monaco", "Consolas", "SFMono-Regular", "ui-monospace", "monospace"],
      sans: ["Roboto", "Helvetica Neue", "ui-sans-serif", "Arial"],
    },
    extend: {
      minHeight: (theme) => ({
        ...theme("spacing"),
      }),
    },
  },

  plugins: [
    require("@tailwindcss/forms")({
      strategy: "class",
    }),
  ],
  corePlugins: {
    preflight: false,
  },
  important: ".psb",
  prefix: "psb-",
  darkMode: "selector",
};
