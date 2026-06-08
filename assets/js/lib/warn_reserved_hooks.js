/**
 * Warns users if they are using reserved hook names that will be overridden.
 * @param {string[]} reservedNames - Array of reserved hook names.
 * @param {Object|null|undefined} userHooks - Object containing user-defined hooks.
 */
export function warnReservedHooks(reservedNames, userHooks) {
  for (const name of Object.keys(userHooks ?? {})) {
    if (reservedNames.includes(name)) {
      console.warn(
        `[phoenix_storybook] Hook "${name}" is reserved by PhoenixStorybook and will be overridden.`,
      );
    }
  }
}
