// Report the state of this opencode session to the desktop, the same way the Claude Code
// hooks do. ~/.local/bin/agent owns the state file; this only tells it what happened.
export const AgentReport = async ({ $ }) => {
  const report = (state) => $`agent report opencode ${state}`.quiet().nothrow()

  return {
    "tool.execute.before": async () => {
      await report("working")
    },

    event: async ({ event }) => {
      switch (event.type) {
        case "permission.asked":
          await report("blocked")
          break
        case "permission.replied":
          await report("working")
          break
        case "session.idle":
          await report("done")
          break
        case "session.deleted":
          await report("gone")
          break
      }
    },
  }
}
