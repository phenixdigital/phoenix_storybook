export function warnReservedHooks(reservedNames, userHooks) {
  for (const name of Object.keys(userHooks ?? {})) {
    if (reservedNames.includes(name)) {
      console.warn(
        `[phoenix_storybook] Hook "${name}" is reserved by PhoenixStorybook and will be overridden.`,
      );
    }
  }
}
