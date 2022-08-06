module.exports = {
  content: ["../lib/**/*.{ex,heex}", "./js/**/*.js"],
  theme: {
    extend: {},
  },
  plugins: [require("tailwindcss-font-inter"), require("@tailwindcss/forms")],
  prefix: "lsb-",
  important: true,
};
