module.exports = {
  content: ["../lib/**/*.{ex,heex}", "./js/**/*.js"],
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
  prefix: "lsb-",
};
