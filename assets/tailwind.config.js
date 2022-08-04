module.exports = {
  content: ["../lib/**/*.{ex,heex}", "./js/**/*.js"],
  theme: {
    extend: {},
  },
  plugins: [require("tailwindcss-font-inter")],
  prefix: "lsb-",
  important: true,
};
