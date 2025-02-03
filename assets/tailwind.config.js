module.exports = {
  safelist: [
    { pattern: /^!?psb-(w|h|m|p)\w?-.+/ },
    {
      pattern:
        /^psb:text-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)(-\d\d\d?)?$/,
    },
  ],
};
