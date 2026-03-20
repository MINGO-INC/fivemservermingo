import plugin from "tailwindcss/plugin";

/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        151515: "#151515",
        202020: "#202020",
        353535: "#353535",
        bcbcbc: "#bcbcbc",
        "4a4a4a": "#4a4a4a",
        a1a1a1: "#a1a1a1",
        "2f2f2f": "#2f2f2f",
        444: "#444",
        C12D2D: "#C12D2D",
        "20846D": "#20846D",
        "1EE8B6": "#1EE8B6",
        "0c0c0c": "#0c0c0c",
        ff6b6b: "#ff6b6b",
        "#7C898D": "#7C898D",
      },
      fontFamily: {
        roboto: "Roboto",
        sfpro: "SF Pro Display",
        sfmono: "SFMONO",
        gilroy: "Gilroy",
        primary: "Gilroy",
      },
      backgroundImage: {
        "shadow-depth":
          "linear-gradient(90deg, #070707 0%, #121212 61%, #000000 100%)",
      },
      fontSize: {
        9: "9px",
        10: "10px",
        11: "11px",
      },
    },
  },
  plugins: [
    plugin(function ({ addUtilities }) {
      const newUtilities = {
        ".scrollbar-hidden::-webkit-scrollbar": { display: "none" },
        ".scrollbar-hidden": {
          "scrollbar-width": "none",
          "-ms-overflow-style": "none",
        },
        ".text-shadow-adez": {
          textShadow: "0px 0px 8px rgba(255, 255, 255, 0.2)",
        },
      };
      addUtilities(newUtilities);
    }),
  ],
};
