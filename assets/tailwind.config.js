module.exports = {
  content: [
    "./css/**/*.css",
    "./js/**/*.js",
    "../lib/**/*.{ex,heex}",
    "../priv/templates/**/*.eex",
  ],
  safelist: [
    { pattern: /^lsb-(w|h|m|p)-.+/ },
    {
      pattern:
        /^lsb-text-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)(-\d\d\d?)?$/,
    },
  ],
  theme: {
    extend: {
      minHeight: (theme) => ({
        ...theme("spacing"),
      }),
    },
  },

  plugins: [
    require("tailwindcss-font-inter"),
    require("@tailwindcss/forms")({
      strategy: "class",
    }),
  ],
  corePlugins: {
    preflight: false,
  },
  important: ".lsb",
  prefix: "lsb-",
};
