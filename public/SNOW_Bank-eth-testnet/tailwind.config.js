/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx,css,scss}"],
  theme: {
    extend: {
      colors: {
        primary: "black",
        secondary: "#2b5e8b30",
        symbol: "#0052ff",
        symbolHover: "#1d2a3b",
        symbolBorder: "#58687bb8",
      },
    },
  },
  plugins: [],
};
