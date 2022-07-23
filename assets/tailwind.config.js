/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["../lib/**/*.{ex,heex}"],
  theme: {
    extend: {},
  },
  plugins: [require("tailwindcss-font-inter")],
  prefix: "lsb-",
  important: true,
};
