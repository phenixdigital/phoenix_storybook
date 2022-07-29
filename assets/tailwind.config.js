/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["../lib/**/*.{ex,heex}", "./js/**/*.js"],
  safelist: [{ pattern: /(bg|text)-.*-(100|200|300|400|500|600|700|800)/ }],
  theme: {
    extend: {},
  },
  plugins: [require("tailwindcss-font-inter")],
  prefix: "lsb-",
  important: true,
};
